USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRateDimensionTemplateBandList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRateDimensionTemplateBandList]
(
	@RateDimensionTemplateID int
)
As

select tbl1.RateDimensionBandID as ID , tbl1.RateDimensionBand as Name
from tb_RateDimensionBand tbl1
where tbl1.flag & 1 <> 1 
and tbl1.RateDimensionTemplateID  = @RateDimensionTemplateID

GO
