USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRateStructureGetDetails]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRateStructureGetDetails]
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

select RateStructureID , RateStructure , ModifiedDate,
       UC_Admin.dbo.FN_GetUserName(ModifiedByID)
from tb_RateStructure
where RateStructureID = @RateStructureID

GO
