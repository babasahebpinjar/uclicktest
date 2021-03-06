USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRateStructureRateTypeList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UIRateStructureRateTypeList]
(
	@RateStructureID int
)
As

-----------------------------------------------------------------------
-- Display the different rate types associated with the rate structure
-----------------------------------------------------------------------

Select tbl3.RateItemID as ID,tbl3.RateItemName as Name
from  tb_RateStructureRateItem tbl2 
inner join tb_RateItem tbl3 on tbl2.RateItemID = tbl3.RateItemID
where tbl2.RateStructureID = @RateStructureID
and tbl3.flag & 1 <> 1
and tbl2.flag & 1 <> 1
and tbl3.RateItemTypeID = 1 -- Rate Type
order by tbl2.Number

GO
