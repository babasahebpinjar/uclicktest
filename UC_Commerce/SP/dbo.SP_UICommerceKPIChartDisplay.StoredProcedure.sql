USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICommerceKPIChartDisplay]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UICommerceKPIChartDisplay]
As


------------------------------------------------------
-- Select TOP N latest offers processed by system
------------------------------------------------------

Select offerid , ExternalOfferFileName , OfferFileName , OfferDate , OfferContent , OfferStatus
from  tb_UIChartTopNOffersProcessed
order by OfferDate desc



-------------------------------------------------------
-- Offer Distribution by Content for Current Month
------------------------------------------------------

Select OfferContent , TotalOffers
from  tb_UIChartOfferDistributionByContent
order by offerContent


-----------------------------------
-- Offer trend in Last N Months 
-----------------------------------

Select MonthYear , OfferContent , TotalOffers
from  tb_UIChartOfferTrendLastNMonths
order by YearMonthNum


------------------------------------------------------------------
-- Top N partners by Number of Rate sheets send in last N Months
------------------------------------------------------------------

Select VendorSource , TotalOffers
from  tb_UIChartTopNPartnersByOffers
order by TotalOffers Desc , VendorSource


-----------------------------------------------------------------------------
-- TOP N Offer Dates by Number of rate sheets received in Current Month
-----------------------------------------------------------------------------

Select OfferDate , TotalOffers
from  tb_UIChartTopNOfferDateByOffers
order by TotalOffers desc , OfferDate desc


------------------------------------------------------------------------------------------
-- Average time taken to process vendor offer by Content Type in Current Month
------------------------------------------------------------------------------------------

Select OfferContent , AverageProcessTimeMin
from  tb_UIChartAverageOfferProcessTimeByContent
order by offerContent
GO
