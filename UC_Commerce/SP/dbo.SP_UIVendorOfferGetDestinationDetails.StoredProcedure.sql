USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIVendorOfferGetDestinationDetails]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_UIVendorOfferGetDestinationDetails]
(
 @VendorOfferID int,
 @DestinationName varchar(60) = NULL ,
 @CountryIDList nvarchar(max),
 @ChangeStatus int ,  -- 0 (All) , 1 (Yes) , 2(No)
 @ErrorDescription varchar(2000) output,
 @ResultFlag int output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0


Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000)

set @DestinationName = rtrim(ltrim(@DestinationName))

if (( @DestinationName is not Null ) and ( len(@DestinationName) = 0 ) )
 set @DestinationName = NULL

if ( ( @DestinationName <> '_') and charindex('_' , @DestinationName) <> -1 )
Begin

 set @DestinationName = replace(@DestinationName , '_' , '[_]')

End

-----------------------------------------------------------------
-- Set the value of change status flag depending on the value
-- passed
-----------------------------------------------------------------

if ( isnull(@ChangeStatus , 0) not in (1,2))
 set @ChangeStatus = NULL


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
Exec SP_UICountryByOfferList NULL ,@VendorOfferID

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
 Return 1

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
 Return 1

End


PROCESSRESULT:

----------------------------------------------------------------
-- Create a temporary table to hold all the destinations for the
-- particular offer.
-----------------------------------------------------------------

Select tbl1.DestinationID , tbl1.Destination , tbl1.EffectiveDate , 
       Case 
   When tbl1.flag & 64 = 64 then 'Y'
   Else 'N'
    End as ChangeFlag,
    tbl3.CountryID , tbl3.Country
into #TempUploadDestination
from tb_UploadDestination tbl1
inner join UC_Reference.dbo.tb_Destination tbl2 on tbl1.DestinationID = tbl2.DestinationID
inner join UC_Reference.dbo.tb_Country tbl3 on tbl2.CountryID = tbl3.CountryID
inner join @CountryIDTable tbl4 on tbl3.CountryID = tbl4.CountryID
where tbl1.offerID = @VendorOfferID


------------------------------------------------------------------
-- Prepare the dynamic SQL to extract the filtered data from the
-- temp table
------------------------------------------------------------------

set @SQLStr = 'Select DestinationID , Destination , CountryID , Country , EffectiveDate , ChangeFlag as Change ' +
        ' from #TempUploadDestination tbl1 ' +
     ' where tbl1.ChangeFlag = ' +
     Case
       When @ChangeStatus is NULL then 'tbl1.ChangeFlag'
     When @ChangeStatus = 1 then '''Y'''
     When @ChangeStatus = 2 then '''N'''
     End

     

set @Clause1 = 
   Case
     When (@DestinationName is NULL) then ''
     When (@DestinationName = '_') then ' and  tbl1.Destination like '  + '''' + '%' + '[_]' + '%' + ''''
     When ( ( Len(@DestinationName) =  1 ) and ( @DestinationName = '%') ) then ''
     When ( right(@DestinationName ,1) = '%' ) then ' and tbl1.Destination like ' + '''' + substring(@DestinationName,1 , len(@DestinationName) - 1) + '%' + ''''
     Else ' and tbl1.Destination like ' + '''' + @DestinationName + '%' + ''''
   End

set @SQLStr = @SQLStr + @Clause1

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by tbl1.Country ,tbl1.Destination ' 

--print @SQLStr

Exec (@SQLStr)


-------------------------------------------------
--  Drop the temp table post processing of data
-------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempUploadDestination') )
 Drop table #TempUploadDestination

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCountryList') )
 Drop table #TempCountryList











GO
