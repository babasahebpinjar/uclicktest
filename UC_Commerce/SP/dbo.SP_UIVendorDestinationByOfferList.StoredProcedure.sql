USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIVendorDestinationByOfferList]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIVendorDestinationByOfferList]
(
    @DestinationName varchar(60) = NULL,
	@CountryIDList nvarchar(max),
	@VendorOfferID int	
)
As


Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000)

set @DestinationName = rtrim(ltrim(@DestinationName))

if (( @DestinationName is not Null ) and ( len(@DestinationName) = 0 ) )
	set @DestinationName = NULL

if ( ( @DestinationName <> '_') and charindex('_' , @DestinationName) <> -1 )
Begin

	set @DestinationName = replace(@DestinationName , '_' , '[_]')

End



Declare @CountryIDTable table (CountryID varchar(100) )

insert into @CountryIDTable
select * from UC_Reference.dbo.FN_ParseValueList ( @CountryIDList )

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

			Create table #TempVendorCountryList(CountryID int , Country varchar(100) )

			insert into #TempVendorCountryList
			Exec SP_UICountryByOfferList NULL , @VendorOfferID

			insert into @CountryIDTable (  CountryID )
			Select countryID
			from #TempVendorCountryList -- Insert all the countries into the temp table
				  
End

------------------------------------------------------------
-- Create temporary table to store dump of all destinations
------------------------------------------------------------

Select distinct tbl1.DestinationID , tbl1.Destination
into #TempUploadDestination
from tb_UploadDestination tbl1
inner join UC_Reference.dbo.tb_Destination tbl2 on tbl1.DestinationID = tbl2.DestinationID
inner join @CountryIDTable tbl3 on tbl2.CountryID = tbl3.CountryID
where offerID = @VendorOfferID


----------------------------
-- Display the result set
----------------------------

set @SQLStr = 'Select DestinationID as ID , Destination as Name ' +
		        ' from #TempUploadDestination tbl1 '

set @Clause1 = 
			Case
					When (@DestinationName is NULL) then ''
					When (@DestinationName = '_') then ' where  tbl1.Destination like '  + '''' + '%' + '[_]' + '%' + ''''
					When ( ( Len(@DestinationName) =  1 ) and ( @DestinationName = '%') ) then ''
					When ( right(@DestinationName ,1) = '%' ) then ' where tbl1.Destination like ' + '''' + substring(@DestinationName,1 , len(@DestinationName) - 1) + '%' + ''''
					Else ' where tbl1.Destination like ' + '''' + @DestinationName + '%' + ''''
			End

set @SQLStr = @SQLStr + @Clause1


--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by tbl1.Destination ' 

--print @SQLStr

Exec (@SQLStr)

-------------------------------------------------------
-- Drop tbe temporary table post processing of data
-------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempUploadDestination') )
	Drop table #TempUploadDestination

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempVendorCountryList') )
	Drop table #TempVendorCountryList
GO
