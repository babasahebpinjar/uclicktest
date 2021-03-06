USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[TempWorking]    Script Date: 5/2/2020 6:18:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[TempWorking] As

Declare @VendorOfferID int,
        @ReDestinationID int,
		@RatetypeID int,
		@RatingMethodID int,
		@AnalysisDate datetime


set @VendorOfferID = 10
set @ReDestinationID = 83854
set @RatetypeID = 101
set	@RatingMethodID = -2
set	@AnalysisDate = '2014-09-01 00:00:00.000'

--------------------------------------------------------------
-- Create temp tables to get all the DD Range and Rates in
-- for the offer , Destination and Analysis Date
---------------------------------------------------------------

select *
into #TempRateAnalysisDetail
from tb_RateAnalysisDetail  
where OfferID = @VendorOfferID
and RefDestinationID = @ReDestinationID
and AnalysisDate = @AnalysisDate

select *
into #TempRateAnalysisRate
from tb_RateAnalysisRate
where OfferID = @VendorOfferID
and RefDestinationID = @ReDestinationID
and AnalysisDate = @AnalysisDate
and RatingMethodID = @RatingMethodID
and RateTypeID = @RatetypeID

-------------------------------------------------
-- Select the Result set for the selected data
-------------------------------------------------

select tbl1.DDFrom , tbl1.DDTo , tbl3.Destination as VendorDestination ,
       tbl2.Rate , 
	   tbl2.RatingMethodID , tbl4.RatingMethod ,
	   tbl2.RateTypeID , tbl7.RateItemName + '- ' + tbl6.RateDimensionBand as Ratetype ,
	   tbl2.EffectiveDate
from #TempRateAnalysisDetail tbl1
left join #TempRateAnalysisRate tbl2
              on tbl1.VendorDestinationID = tbl2.VendorDestinationID
left join UC_Reference.dbo.tb_Destination tbl3 on tbl1.VendorDestinationID = tbl3.DestinationID
left Join UC_Reference.dbo.tb_RatingMethod tbl4 on tbl2.RatingMethodID = tbl4.RatingMethodID                                              
left Join UC_Reference.dbo.tb_RateNumberIdentifier tbl5 on tbl4.RatingMethodID = tbl5.RatingMethodID
                                                            and tbl2.RateTypeID = tbl5.RateItemID
left Join UC_Reference.dbo.tb_RateDimensionBand tbl6 on tbl5.RateDimension1BandID = tbl6.RateDimensionBandID
left Join UC_Reference.dbo.tb_RateItem tbl7 on tbl2.RateTypeID = tbl7.RateItemID
order by substring(tbl1.DDFrom , len(tbl1.CountryCode) + 1 , 1)

-------------------------------------------------------
-- Drop the temporary tables post processing of data
-------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempRateAnalysisRate') )
	Drop table #TempRateAnalysisRate

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempRateAnalysisDetail') )
	Drop table #TempRateAnalysisDetail
GO
