USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRatePlanRateList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRatePlanRateList]
(
	@RatePlanID  int ,
	@NumberPlanTypeID int,
	@SelectDate Datetime,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int output

)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

-----------------------------------------------------------------------------
-- Check to ensure that the RatePlan ID is not NULL and exists in the system
-----------------------------------------------------------------------------

if ( @RatePlanID is null )
Begin

		set @ErrorDescription = 'ERROR !!! Rate Plan ID cannot be NULL. Please pass a valid value'
		set @ResultFlag = 1
		Return 1

End

if not exists ( select 1 from tb_RatePlan where RatePlanID = @RatePlanID )
Begin

		set @ErrorDescription = 'ERROR !!! Rate Plan does not exist in the system. Please check details'
		set @ResultFlag = 1
		Return 1

End

-------------------------------------------------------------------------
-- Make sure that the Number Plan Type ID is not NULL and exists in the 
-- system
-------------------------------------------------------------------------

if ( @NumberPlanTypeID is null )
Begin

		set @ErrorDescription = 'ERROR !!! Number Plan Type ID cannot be NULL. Please pass a valid value'
		set @ResultFlag = 1
		Return 1

End

if not exists ( select 1 from tb_NumberPlanType where NumberPlanTypeID = @NumberPlanTypeID )
Begin

		set @ErrorDescription = 'ERROR !!! Number Plan Type ID does not exist in the system. Please check details'
		set @ResultFlag = 1
		Return 1

End

---------------------------------------------------------
-- Get all the essential information from the Rate Plan
---------------------------------------------------------

select RT.RatePlanID ,RT.RateID ,Dest.Destination + '-' + CP.CallType as RateEntity , Dest.DestinationID , CP.CallTypeID,
       RM.RatingMethodID , RM.RatingMethod , RM.RateStructureID , RT.BeginDate , RT.EndDate,
	   RT.ModifiedDate, UC_Admin.dbo.FN_GetUserName(RT.ModifiedByID) as ModifiedByUser
from tb_Rate RT
inner join tb_Destination Dest on RT.DestinationID = Dest.DestinationID
inner join tb_CallType CP on RT.CallTypeID = CP.CallTypeID
inner join tb_Numberplan NP on Dest.NumberPlanID = NP.NumberPlanID
inner join tb_RatingMethod RM on RT.RatingMethodID = RM.RatingMethodID
where RT.RatePlanID = @RatePlanID
and NP.NumberPlanTypeID = @NumberPlanTypeID
and @SelectDate between RT.BeginDate and isNULL(RT.EndDate , @SelectDate)
order by Dest.Destination

GO
