USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIVendorOfferGetRateDetails]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIVendorOfferGetRateDetails]
(
	@VendorOfferID int,
	@DestinationName varchar(60) = NULL ,
	@CountryIDList nvarchar(max),
	@RateStatus int, -- 0 For 'All' , 1 For 'Decrease' , 2 For 'Increase' , 3 For 'Same'
	@ErrorDescription varchar(2000) output,
	@ResultFlag int output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0


Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000),
		@Clause2 varchar(1000)

set @DestinationName = rtrim(ltrim(@DestinationName))

if (( @DestinationName is not Null ) and ( len(@DestinationName) = 0 ) )
	set @DestinationName = NULL

if ( ( @DestinationName <> '_') and charindex('_' , @DestinationName) <> -1 )
Begin

	set @DestinationName = replace(@DestinationName , '_' , '[_]')

End


----------------------------------------------------------------
-- Set the Rate Status flag to NULL in case the value is 0 (ALL)
----------------------------------------------------------------

if (@RateStatus = 0 ) 
	set @RateStatus = NULL

------------------------------------------------------------------
-- Check to ensure that the Vendor OfferID is not null or invalid
------------------------------------------------------------------

if ( ( @VendorOfferID is Null) or not exists (select 1 from tb_Offer where OfferID = @VendorOfferID and OfferTypeID = -1) )
Begin

	set @ErrorDescription = 'ERROR !!!! Vendor Offer ID cannot be NULL or an invalid value'
	set @ResultFlag = 1
	return 1

End

-------------------------------------------------------------
-- Get the list of all the countries being offered in the offer
-------------------------------------------------------------

Create Table #TempCountryList
(
	CountryID int,
	Country varchar(100)
)


insert into #TempCountryList
Exec SP_UICountryByOfferList NULL , @VendorOfferID

Declare @CountryIDTable table (CountryID varchar(100) )

insert into @CountryIDTable
select * from UC_Reference.dbo.FN_ParseValueList ( @CountryIDList )

----------------------------------------------------------------
-- Check to ensure that none of the values are non numeric
----------------------------------------------------------------

if exists ( select 1 from @CountryIDTable where ISNUMERIC(CountryID) = 0 )
Begin

	set @ErrorDescription = 'ERROR !!! List of Country IDs passed contain a non numeric value'
	set @ResultFlag = 1
	GOTO PROCESSEND

End


------------------------------------------------------
-- Check if the All the countries have been selected 
------------------------------------------------------

if exists (
				select 1 
				from @CountryIDTable 
				where CountryID = 0
			)
Begin

			Delete from @CountryIDTable -- Remove all records

			insert into @CountryIDTable (  CountryID )
			Select countryID
			from #TempCountryList  -- Insert all the countries present in the offer

			GOTO PROCESSRESULT
				  
End
		
-------------------------------------------------------------------
-- Check to ensure that all the Country IDs passed are valid values
-------------------------------------------------------------------
		
if exists ( 
				select 1 
				from @CountryIDTable 
				where CountryID not in
				(
					Select CountryID
					from #TempCountryList
				)
			)
Begin

	set @ErrorDescription = 'ERROR !!! List of Country IDs passed contain value(s) which are not valid or do not exist'
	set @ResultFlag = 1
	GOTO PROCESSEND

End


PROCESSRESULT:

----------------------------------------------------------------
-- Create a temporary table to hold all the destinations for the
-- particular offer.
-----------------------------------------------------------------

Select tbl1.UploadDestinationID , tbl1.DestinationID , tbl1.Destination , tbl1.RatingMethodID
into #TempUploadDestination
from tb_UploadDestination tbl1
inner join UC_Reference.dbo.tb_Destination tbl2 on tbl1.DestinationID = tbl2.DestinationID
inner join UC_Reference.dbo.tb_Country tbl3 on tbl2.CountryID = tbl3.CountryID
inner join @CountryIDTable tbl4 on tbl3.CountryID = tbl4.CountryID
where tbl1.offerID = @VendorOfferID


-------------------------------------------------------------------
-- Create table to store all the uploaded rates for the vendor offer
-------------------------------------------------------------------

select *
into #TempUploadRate
from tb_UploadRate
where offerID = @VendorOfferID

-------------------------------------------------------------------
-- Create the data result set based on the passed value in the
-- Rating status
-------------------------------------------------------------------

select tbl2.DestinationID , tbl2.Destination,
       tbl1.EffectiveDate , tbl1.Rate,	
	   tbl5.RateItemName + '-' + tbl4.RateDimensionBand as RateType,
	   Case

			When tbl1.PrevBeginDate is NULL then 'New'
			Else
				Case
					When tbl1.AmountChange = 0 then '0.00%'
					Else convert(varchar(20) , convert(decimal(19,2) , (tbl1.AmountChange/tbl1.Rate)*100 )) + '%'
				End
	   End as PercentChange,
	   Case

			When tbl1.PrevBeginDate is NULL then 'New'
			Else convert(varchar(20) , tbl1.AmountChange)
	   End as AmountChange,
	   Case

			When tbl1.PrevBeginDate is NULL then convert(Decimal(19,6) , 0)
			Else convert(decimal(19,6) ,Rate + (AmountChange * -1.0))
	   End as PrevRate,
	   tbl1.PrevBeginDate,
	   Case
			When tbl1.Flag & 64 = 64 then
				Case
					When AmountChange > 0 then 2 --'Increase'
					When AmountChange < 0 then 1 --'Decrease'
				End
			Else 3 --'Same'
	   End as RateStatus
into #TempResultSet
from #TempUploadRate tbl1
inner join #TempUploadDestination tbl2 on tbl1.UploadDestinationID = tbl2.UploadDestinationID
inner join UC_Reference.dbo.tb_RateNumberIdentifier tbl3 on tbl2.RatingMethodID = tbl3.RatingMethodID
                                           and tbl1.RateTypeID = tbl3.RateItemID
inner join UC_Reference.dbo.tb_RateDimensionBand tbl4 on tbl3.RateDimension1BandID = tbl4.RateDimensionBandID
inner join UC_Reference.dbo.tb_RateItem tbl5 on tbl3.RateItemID = tbl5.RateItemID

------------------------------------------------------------------
-- Prepare the dynamic SQL to extract the filtered data from the
-- temp table
------------------------------------------------------------------

set @SQLStr = 'Select DestinationID,Destination,EffectiveDate,Rate,RateType,PercentChange,AmountChange,PrevRate,PrevBeginDate, '+
               '  Case '+
			   '      When RateStatus = 1 then ''Decrease'' ' +
			   '      When RateStatus = 2 then ''Increase'' ' +
			   '      When RateStatus = 3 then ''Same'' ' +
			   '  End  as RateStatus' +
		       ' from #TempResultSet tbl1 '

set @Clause1 = 
			Case
					When (@DestinationName is NULL) then ''
					When (@DestinationName = '_') then ' where  tbl1.Destination like '  + '''' + '%' + '[_]' + '%' + ''''
					When ( ( Len(@DestinationName) =  1 ) and ( @DestinationName = '%') ) then ''
					When ( right(@DestinationName ,1) = '%' ) then ' where tbl1.Destination like ' + '''' + substring(@DestinationName,1 , len(@DestinationName) - 1) + '%' + ''''
					Else ' where tbl1.Destination like ' + '''' + @DestinationName + '%' + ''''
			End

set @Clause2 = 
			Case
					When (@RateStatus is NULL) then ''
					Else 
					   Case
							When (@DestinationName is NULL) then ' where tbl1.RateStatus =  '  + convert(varchar(20) , @RateStatus)
							Else ' and  tbl1.RateStatus =  '  + convert(varchar(20) , @RateStatus)
					   End
			End

set @SQLStr = @SQLStr + @Clause1 + @Clause2

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by tbl1.Destination ' 

--print @SQLStr

Exec (@SQLStr)


PROCESSEND:

-------------------------------------------------
--  Drop the temp table post processing of data
-------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempUploadRate') )
	Drop table #TempUploadRate

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempUploadDestination') )
	Drop table #TempUploadDestination

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempResultSet') )
	Drop table #TempResultSet

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCountryList') )
	Drop table #TempCountryList


Return 0
GO
