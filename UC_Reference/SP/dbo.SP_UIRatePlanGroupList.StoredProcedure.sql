USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRatePlanGroupList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRatePlanGroupList]
(
	@RatePlanGroupID int = NULL
)
As

Select RatePlanGroupID ,  RatePlanGroup , RatePlanGroupAbbrv ,
       ModifiedDate , UC_Admin.dbo.FN_GetUserName(ModifiedByID) as ModifiedByUser
from tb_RatePlanGroup
where flag & 1 <> 1
and RatePlanGroupID = isnull(@RatePlanGroupID , RatePlanGroupID)
order by RatePlanGroup
GO
