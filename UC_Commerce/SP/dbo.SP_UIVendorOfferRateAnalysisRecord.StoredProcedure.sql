USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIVendorOfferRateAnalysisRecord]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIVendorOfferRateAnalysisRecord]
(
	@RateAnalysisID int 
)
As

select tbl1.RateAnalysisID,
       tbl1.RefDestinationID as DestinationID , tbl6.Destination,
       tbl1.AnalysisDate , tbl3.RatingMethodID ,tbl3.RatingMethod,
	   tbl2.RateTypeID , tbl9.RateItemName + '- ' + tbl5.RateDimensionBand as Ratetype , 
	   tbl2.AnalyzedRate , 
	   tbl2.PrevRate , tbl2.PrevBeginDate,
	   tbl1.DiscrepancyFlag
from tb_RateAnalysis tbl1
inner join tb_RateAnalysisSummary tbl2 on tbl1.RateAnalysisID = tbl2.RateAnalysisID
inner join UC_Reference.dbo.tb_RatingMethod tbl3 on tbl1.RatingMethodID = tbl3.RatingMethodID
inner join UC_Reference.dbo.tb_RateNumberIdentifier tbl4 on tbl3.RatingMethodID = tbl4.RatingMethodID
                                                          and 
														    tbl2.RateTypeID = tbl4.RateItemID
inner join UC_Reference.dbo.tb_RateDimensionBand tbl5 on tbl4.RateDimension1BandID = tbl5.RateDimensionBandID
inner join UC_Reference.dbo.tb_Destination tbl6 on tbl1.RefDestinationID = tbl6.DestinationID
inner join UC_Reference.dbo.tb_RateItem tbl9 on tbl2.RateTypeID = tbl9.RateItemID
where tbl1.RateAnalysisID = @RateAnalysisID                          



Return

GO
