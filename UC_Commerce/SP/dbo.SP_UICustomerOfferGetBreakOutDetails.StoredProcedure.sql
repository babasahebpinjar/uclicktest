USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICustomerOfferGetBreakOutDetails]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UICustomerOfferGetBreakOutDetails]
(
	@CustomerOfferID int,
	@Prefix varchar(60) = NULL ,
	@DestinationIDList nvarchar(max),
	@ErrorDescription varchar(2000) output,
	@ResultFlag int output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0


Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000)

set @Prefix = rtrim(ltrim(@Prefix))

if (( @Prefix is not Null ) and ( len(@Prefix) = 0 ) )
	set @Prefix = NULL

if ( ( @Prefix <> '_') and charindex('_' , @Prefix) <> -1 )
Begin

	set @Prefix = replace(@Prefix , '_' , '[_]')

End


------------------------------------------------------------------
-- Check to ensure that the Vendor OfferID is not null or invalid
------------------------------------------------------------------

if ( ( @CustomerOfferID is Null) or not exists (select 1 from tb_Offer where OfferID = @CustomerOfferID and OfferTypeID = -2) )
Begin

	set @ErrorDescription = 'ERROR !!!! Customer Offer ID cannot be NULL or an invalid value'
	set @ResultFlag = 1
	return 1

End

--------------------------------------------------------------------
-- Get the list of all the destinations provided in the vendor offer
--------------------------------------------------------------------

select UploadDestinationID , Destination , DestinationID
into #TempAllDestinationList 
from tb_UploadDestination
where OfferID = @CustomerOfferID


Declare @DestinationIDTable table (DestinationID varchar(100) )

insert into @DestinationIDTable
select * from UC_Reference.dbo.FN_ParseValueList ( @DestinationIDList )

----------------------------------------------------------------
-- Check to ensure that none of the values are non numeric
----------------------------------------------------------------

if exists ( select 1 from @DestinationIDTable where ISNUMERIC(DestinationID) = 0 )
Begin

	set @ErrorDescription = 'ERROR !!! List of Destination IDs passed contain a non numeric value'
	set @ResultFlag = 1
	Return 1

End


-------------------------------------------------------
-- Check if the All the Destinations have been selected 
--------------------------------------------------------

if exists (
				select 1 
				from @DestinationIDTable 
				where DestinationID = 0
			)
Begin

			Delete from @DestinationIDTable -- Remove all records

			insert into @DestinationIDTable (  DestinationID )
			Select distinct DestinationID
			from #TempAllDestinationList
			
			GOTO PROCESSRESULT
				  
End
		
-------------------------------------------------------------------
-- Check to ensure that all the Country IDs passed are valid values
-------------------------------------------------------------------
		
if exists ( 
				select 1 
				from @DestinationIDTable 
				where DestinationID not in
				(
					Select distinct DestinationID
					from #TempAllDestinationList					
				)
			)
Begin

	set @ErrorDescription = 'ERROR !!! List of Destination IDs passed contain value(s) which are not valid or do not exist'
	set @ResultFlag = 1
	Return 1

End


PROCESSRESULT:

----------------------------------------------------------------
-- Create Temp table to hold all the breakouts being offered
-- in the vendor offer
-----------------------------------------------------------------

Select UploadBreakoutID , UploadDestinationID, DialedDigit , CountryCode,
       EffectiveDate , Flag
into #TempUploadBreakout
from tb_UploadBreakout
where OfferID = @CustomerOfferID

----------------------------------------------------------------
-- Create a temporary table to hold all the destinations for the
-- particular offer.
-----------------------------------------------------------------

Select tbl2.DestinationID , tbl2.Destination , tbl1.DialedDigit , tbl1.EffectiveDate , 
       Case 
			When tbl1.flag & 64 = 64 then 'Y'
			Else 'N'
	   End as ChangeFlag
into #TempAllResultData 
from #TempUploadBreakout tbl1
inner join #TempAllDestinationList tbl2 on tbl1.UploadDestinationID = tbl2.UploadDestinationID
inner join @DestinationIDTable tbl3 on tbl2.DestinationID = tbl3.DestinationID

------------------------------------------------------------------
-- Prepare the dynamic SQL to extract the filtered data from the
-- temp table
------------------------------------------------------------------

set @SQLStr = 'Select DestinationID , Destination , DialedDigit , EffectiveDate , ChangeFlag  ' +
		        ' from #TempAllResultData tbl1 '

set @Clause1 = 
			Case
					When (@Prefix is NULL) then ''
					When (@Prefix = '_') then ' where  tbl1.DialedDigit like '  + '''' + '%' + '[_]' + '%' + ''''
					When ( ( Len(@Prefix) =  1 ) and ( @Prefix = '%') ) then ''
					When ( right(@Prefix ,1) = '%' ) then ' where tbl1.DialedDigit like ' + '''' + substring(@Prefix,1 , len(@Prefix) - 1) + '%' + ''''
					Else ' where tbl1.DialedDigit like ' + '''' + @Prefix + '%' + ''''
			End

set @SQLStr = @SQLStr + @Clause1

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by tbl1.Destination , tbl1.DialedDigit ' 

--print @SQLStr

Exec (@SQLStr)


-------------------------------------------------
--  Drop the temp table post processing of data
-------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAllDestinationList') )
	Drop table #TempAllDestinationList

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempUploadBreakout') )
	Drop table #TempUploadBreakout

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAllResultData') )
	Drop table #TempAllResultData


Return 0


-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by tbl1.Destination , tbl1.DialedDigit ' 

--print @SQLStr

Exec (@SQLStr)


-------------------------------------------------
--  Drop the temp table post processing of data
-------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAllDestinationList') )
	Drop table #TempAllDestinationList

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempUploadBreakout') )
	Drop table #TempUploadBreakout

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAllResultData') )
	Drop table #TempAllResultData


Return 0
GO
