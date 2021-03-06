USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSCheckVendorDestinationIsROC]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSCheckVendorDestinationIsROC]
(

	@OfferID int
)
As

select distinct RefDestinationID , VendorDestinationID , AnalysisDate ,CountryCode
into #TempRateAnalysisDetail
from tb_RateAnalysisDetail 
where offerID = @OfferID

------------------------------------------------------------------------
-- Analyze the Vendor Destinations against the Country Codes to
-- Establish the ROC destinations
------------------------------------------------------------------------

Select Distinct RefDestinationID,
       AnalysisDate,
       VendorDestinationID
From  #TempRateAnalysisDetail tbl1
inner join UC_Reference.dbo.tb_DialedDigits tbl2 on tbl1.VendorDestinationID = tbl2.DestinationID
where tbl1.AnalysisDate between tbl2.BeginDate and isnull(tbl2.EndDate , tbl1.AnalysisDate) 
and tbl2.DialedDigits = tbl1.CountryCode


--------------------------------------------------------
-- Drop all the temporary tables created during the process
-----------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempRateAnalysisDetail') )
	Drop table #TempRateAnalysisDetail
GO
