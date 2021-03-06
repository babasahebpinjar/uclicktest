USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIReferenceCountryByOfferList]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UIReferenceCountryByOfferList]
(
    @Country varchar(100) = NULL,
	@VendorOfferID int
)
As


Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000)



if (( @Country is not Null ) and ( len(@Country) = 0 ) )
	set @Country = NULL


if ( ( @Country <> '_') and charindex('_' , @Country) <> -1 )
Begin

	set @Country = replace(@Country , '_' , '[_]')

End

------------------------------------------------------------
-- Create temporary table to store dump of all destinations
------------------------------------------------------------

Select RefDestinationID
into #TempRateAnalysisDestination
from tb_RateAnalysis
where offerID = @VendorOfferID

----------------------------------------------------------------------
-- Create a table to store all the distinct countries being offered
----------------------------------------------------------------------

Create table #TempCountryList
(
	CountryID int,
	Country varchar(100)
)

-----------------------------------------------------------
-- Insert the Country for all the Destinations being offered
-----------------------------------------------------------

insert into #TempCountryList
(
	CountryID,
	Country
)
select Distinct tbl3.CountryID , tbl3.Country
from #TempRateAnalysisDestination tbl1
inner join UC_Reference.dbo.tb_Destination tbl2 on tbl1.RefDestinationID = tbl2.DestinationID
inner join UC_Reference.dbo.tb_Country tbl3 on tbl2.CountryID = tbl3.CountryID

------------------------------------------------
-- Display the data result set post processing
------------------------------------------------

set @SQLStr = 'Select CountryID as ID , Country as Name ' +
			  ' from #TempCountryList tbl1 '

--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------

set @Clause1 = 
           Case
			   When (@Country is NULL) then ''
			   When (@Country = '_') then ' where tbl1.Country like '  + '''' + '%' + '[_]' + '%' + ''''
			   When ( ( Len(@Country) =  1 ) and ( @Country = '%') ) then ''
			   When ( right(@Country ,1) = '%' ) then ' where tbl1.Country like ' + '''' + substring(@Country,1 , len(@Country) - 1) + '%' + ''''
			   Else ' where tbl1.Country like ' + '''' + @Country + '%' + ''''
	       End	
		   
-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by tbl1.Country' 

--print @SQLStr

Exec (@SQLStr)		   		 			 			 

-------------------------------------------------------
-- Drop tbe temporary table post processing of data
-------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempRateAnalysisDestination') )
	Drop table #TempRateAnalysisDestination

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempUploadBreakoutCountryCode') )
	Drop table #tempUploadBreakoutCountryCode

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCountryList') )
	Drop table #TempCountryList
GO
