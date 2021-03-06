USE [UC_Bridge]
GO
/****** Object:  View [dbo].[vw_RatingMethodInfo]    Script Date: 5/2/2020 6:44:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE View [dbo].[vw_RatingMethodInfo]
As

select tbl1.RatingMethodID , tbl1.RatingMethod , tbl3.RateDimensionTemplateID, tbl3.RateDimensionTemplate,
       tbl4.RateDimensionBandID , tbl4.RateDimensionBand,
	   tbl5.RateItemID , tbl6.RateItemName
from Referenceserver.uc_reference.dbo.tb_ratingmethod tbl1
inner join Referenceserver.uc_reference.dbo.tb_ratingmethoddetail tbl2 on tbl1.RatingMethodID = tbl2.RatingmethodID
inner join Referenceserver.uc_reference.dbo.tb_RateDimensionTemplate tbl3 on convert(int , tbl2.ItemValue) = tbl3.RateDimensionTemplateID
inner join Referenceserver.uc_reference.dbo.tb_RateDimensionBand tbl4 on tbl3.RateDimensionTemplateID = tbl4.RateDimensionTemplateID
inner join Referenceserver.uc_reference.dbo.tb_RateNumberIdentifier tbl5 on tbl1.RatingMethodID = tbl5.RatingMethodID and tbl4.RateDimensionBandID = tbl5.RateDimension1BandID
inner join Referenceserver.uc_reference.dbo.tb_RateItem tbl6 on tbl5.RateItemID = tbl6.RateItemID
where tbl1.RateStructureID = 1 -- SEP rating structures
and tbl2.RateItemID = 301 -- Date Time Dimension Band






GO
