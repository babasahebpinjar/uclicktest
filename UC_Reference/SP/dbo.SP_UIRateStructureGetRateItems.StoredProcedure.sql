USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRateStructureGetRateItems]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRateStructureGetRateItems]
(
	@RateStructureID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

------------------------------------------------------------------------
-- Make sure that Rating Method ID is not NULL and exists in the system
------------------------------------------------------------------------

if (
		(@RateStructureID is NULL )
		or
		not exists ( select 1 from tb_RateStructure where RateStructureID = @RateStructureID and flag & 1 <> 1 )
   )
Begin

		set @ErrorDescription = 'ERROR !!! Rate Structure ID is NULL or does not exist in the system'
		set @ResultFlag = 1
		Return 1

End

--------------------------------------------------
-- Display the details related to rating structure
--------------------------------------------------

Select tbl3.RateItemID ,tbl3.RateItemName , tbl2.Number,
	   tbl3.RateItemDescription , tbl4.RateItemTypeID ,tbl4.RateItemType
from  tb_RateStructureRateItem tbl2 
inner join tb_RateItem tbl3 on tbl2.RateItemID = tbl3.RateItemID
inner join tb_RateItemType tbl4 on tbl3.RateItemTypeID = tbl4.RateItemTypeID
where tbl2.RateStructureID = @RateStructureID
and tbl3.flag & 1 <> 1
and tbl2.flag & 1 <> 1
order by tbl4.RateItemTypeID , tbl2.Number

GO
