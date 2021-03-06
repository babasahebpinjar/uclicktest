USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRateDimensionTemplateGetBandInfo]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRateDimensionTemplateGetBandInfo]
(
	@RateDimensionTemplateID int,
	@UserID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

----------------------------------------------------------------
-- Rate Dimension Templtae should not be NULL and have a valid
-- value
----------------------------------------------------------------

if ( (@RateDimensionTemplateID is NULL ) 
     or
	 not exists ( select 1 from tb_RateDimensionTemplate where RateDimensionTemplateID = @RateDimensionTemplateID )
   )
Begin

		set @ErrorDescription = 'ERROR !!! Rate Dimension Template ID is NULL or not valid and does not exist in the system'
		set @ResultFlag = 1
		Return 1
End

Select RateDimensionBandID , RateDimensionBand , RateDimensionBandAbbrv,
       RateDimensionTemplateID , ModifiedDate,
	   UC_Admin.dbo.FN_GetUserName(ModifiedByID) as ModifiedByUser
from tb_RateDimensionBand
where RateDimensionTemplateID = @RateDimensionTemplateID

Return 0
GO
