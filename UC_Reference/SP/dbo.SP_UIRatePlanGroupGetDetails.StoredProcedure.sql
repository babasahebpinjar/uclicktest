USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRatePlanGroupGetDetails]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  Procedure [dbo].[SP_UIRatePlanGroupGetDetails] 
(
	@RatePlanGroupID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ResultFlag = 0
set @ErrorDescription = NULL


if ( @RatePlanGroupID is null )
Begin

		set @ErrorDescription = 'ERROR !!! Rate Plan Group ID cannot be NULL. Please pass a valid value'
		set @ResultFlag = 1
		Return 1

End

if not exists ( select 1 from tb_RatePlanGroup where RatePlanGroupID = @RatePlanGroupID )
Begin

		set @ErrorDescription = 'ERROR !!! Rate Plan Group does not exist in the system. Please check details'
		set @ResultFlag = 1
		Return 1

End

Select RatePlanGroupID ,  RatePlanGroup , RatePlanGroupAbbrv 
from tb_RatePlanGroup
where RatePlanGroupID = @RatePlanGroupID 


Return 0

GO
