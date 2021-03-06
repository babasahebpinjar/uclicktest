USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIVendorOfferRateAnalysis]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIVendorOfferRateAnalysis]
(
	@VendorOfferID int ,
	@AnalyzeStatus int ,-- 0 All , 1 Any Errors , 2 Rate Gap , 3 Dialed Digits Gap , 4 Rating Method Gap , 5 No Errors
	@CountryIDList nvarchar(max),
	@DestinationIDList nvarchar(max) ,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @SQLStr varchar(max),
        @Clause varchar(2000)

-----------------------------------------------------------------
-- Create table for list of all selected destinations from the 
-- parameter passed
-----------------------------------------------------------------

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

Create table #TempCountryList(CountryID int , Country varchar(100) )

insert into #TempCountryList
Exec SP_UIReferenceCountryByOfferList NULL , @VendorOfferID

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
			from #TempCountryList -- Insert all the countries into the temp table
				
				  
End
		


Declare @DestinationIDTable table (DestinationID varchar(100) )

insert into @DestinationIDTable
select * from UC_REference.dbo.FN_ParseValueList ( @DestinationIDList )

----------------------------------------------------------------
-- Check to ensure that none of the values are non numeric
----------------------------------------------------------------

if exists ( select 1 from @DestinationIDTable where ISNUMERIC(DestinationID) = 0 )
Begin

	set @ErrorDescription = 'ERROR !!! List of Destination IDs passed contain a non numeric value'
	set @ResultFlag = 1
	Return 1

End

------------------------------------------------------
-- Check if the All the Destinations have been selected 
------------------------------------------------------

if (
			exists (
						select 1 
						from @DestinationIDTable 
						where DestinationID = 0
					)
					or
					(
					(select count(*) from @DestinationIDTable ) = 0
					)
	)
Begin

			Delete from @DestinationIDTable -- Remove all records

			insert into @DestinationIDTable (  DestinationID )
			Select distinct RefDestinationID
			from tb_RateAnalysis
			where OfferID = @VendorOfferID

				 				  
End



----------------------------------------------------------------------
-- Store data in temporary tables for the essential vendor offer
----------------------------------------------------------------------

select *
into #TempRateAnalysis
from tb_RateAnalysis
where offerID = @VendorOfferID


select tbl1.*
into #TempRateAnalysisSummary
from tb_RateAnalysisSummary tbl1
inner join #TempRateAnalysis tbl2 on tbl1.RateAnalysisID = tbl2.RateAnalysisID


-------------------------------------------------------
-- Create Temp table to store all the result set data
-------------------------------------------------------

Create table #TempRateAnalysisResult
(
    RateAnalysisID int,
	DestinationID int,
	Destination varchar(100),
	AnalysisDate datetime,
	RatingMethodId int,
	RatingMethod varchar(100),
	RatetypeID int ,
	RateType varchar(200),
	AnalyzedRate decimal(19,6),
	PrevRate decimal(19,6),
	PrevBeginDate datetime,
	DiscrepancyFlag int,
	Remarks varchar(500)
)


insert into #TempRateAnalysisResult
(
    RateAnalysisID,
	DestinationID ,
	Destination ,
	AnalysisDate ,
	RatingMethodID,
	RatingMethod,
	RatetypeID,
	RateType ,
	AnalyzedRate ,
	PrevRate,
	PrevBeginDate,
	DiscrepancyFlag 
)
select tbl1.RateAnalysisID,
       tbl1.RefDestinationID as DestinationID , tbl6.Destination,
       tbl1.AnalysisDate , tbl3.RatingMethodID ,tbl3.RatingMethod,
	   tbl2.RateTypeID , tbl9.RateItemName + '- ' + tbl5.RateDimensionBand , 
	   tbl2.AnalyzedRate , 
	   tbl2.PrevRate , tbl2.PrevBeginDate,
	   tbl1.DiscrepancyFlag
from #TempRateAnalysis tbl1
inner join #TempRateAnalysisSummary tbl2 on tbl1.RateAnalysisID = tbl2.RateAnalysisID
inner join UC_Reference.dbo.tb_RatingMethod tbl3 on tbl1.RatingMethodID = tbl3.RatingMethodID
inner join UC_Reference.dbo.tb_RateNumberIdentifier tbl4 on tbl3.RatingMethodID = tbl4.RatingMethodID
                                                          and 
														    tbl2.RateTypeID = tbl4.RateItemID
inner join UC_Reference.dbo.tb_RateDimensionBand tbl5 on tbl4.RateDimension1BandID = tbl5.RateDimensionBandID
inner join UC_Reference.dbo.tb_Destination tbl6 on tbl1.RefDestinationID = tbl6.DestinationID
inner join @DestinationIDTable tbl7 on tbl6.DestinationID = tbl7.DestinationID
inner join @CountryIDTable tbl8 on tbl6.CountryID = tbl8.CountryID
inner join UC_Reference.dbo.tb_RateItem tbl9 on tbl2.RateTypeID = tbl9.RateItemID
where OfferID = @VendorOfferID                             

-------------------------------------------------------------
-- Update the Remarks section depending on the Discrepancy
-- Flag
-------------------------------------------------------------

update #TempRateAnalysisResult
set Remarks = isnull(Remarks, '') + 'Rate Gap'
where DiscrepancyFlag & 2 = 2

update #TempRateAnalysisResult
set Remarks = 
		Case
			When Remarks is not Null then Remarks + ' , ' + 'Dialed Digits Gap'
			Else isnull(Remarks, '') + 'Dialed Digits Gap'
		End
where DiscrepancyFlag & 4 = 4


update #TempRateAnalysisResult
set Remarks = 
		Case
			When Remarks is not Null then Remarks + ' , ' + 'Rating Method Gap'
			Else isnull(Remarks, '') + 'Rating Method Gap'
		End
where DiscrepancyFlag & 8 = 8

----------------------------------------------
-- Display the result set post processing
----------------------------------------------

set @SQLStr = 'Select
                RateAnalysisID,
				DestinationID ,
				Destination ,
				AnalysisDate ,
				RatingMethodID ,
				RatingMethod ,
				RatetypeID ,
				RateType ,
				AnalyzedRate ,
				PrevRate,
				PrevBeginDate,
				Remarks 
			from #TempRateAnalysisResult ' + Char(10) 

set @Clause =
		Case
			When @AnalyzeStatus = 1 then ' where DiscrepancyFlag <> 0 '
			When @AnalyzeStatus = 2 then ' where DiscrepancyFlag & 2 = 2 '
			When @AnalyzeStatus = 3 then ' where DiscrepancyFlag & 4 = 4 '
			When @AnalyzeStatus = 4 then ' where DiscrepancyFlag & 8 = 8 '
			When @AnalyzeStatus = 5 then ' where DiscrepancyFlag = 0 '
			Else ''
		End
		


set @SQLStr = @SQLStr + @Clause

set @SQLStr = @SQLStr + char(10) + ' order by Destination , AnalysisDate'

Exec(@SQLStr)

-------------------------------------------------------
-- Drop the temporary table post processing of data
-------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempRateAnalysisResult') )
	Drop table #TempRateAnalysisResult

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCountryList') )
	Drop table #TempCountryList

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempRateAnalysis') )
	Drop table #TempRateAnalysis

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempRateAnalysisSummary') )
	Drop table #TempRateAnalysisSummary

Return


GO
