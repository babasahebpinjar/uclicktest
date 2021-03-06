USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRatePlanDelete]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRatePlanDelete]
(
    @RatePlanID int,
	@UserID int,
	@ErrorDescription varchar(2000) output,
	@ResultFlag int Output	
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

-----------------------------------------------
-- Check and validate all the input parameters
-----------------------------------------------

if ( @RatePlanID is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Rate Plan ID cannot be NULL'
	set @ResultFlag = 1
	Return 1


End


if not exists (select 1 from tb_RatePlan where RatePlanID =  @RatePlanID)
Begin

	set @ErrorDescription = 'ERROR !!! Rate Plan ID is not valid and doesnot exist in the system'
	set @ResultFlag = 1
	Return 1


End

-----------------------------------------------------
-- Check if the rate plan has any associated rates 
-----------------------------------------------------

if exists ( select 1 from tb_rate where RateplanID = @RatePlanID )
Begin

	set @ErrorDescription = 'ERROR !!! Cannot delete Rate Plan as it has associated rates'
	set @ResultFlag = 1
	Return 1

End

-----------------------------------------------------------------------
-- Check if the Rate Plan is associated with an Active Vendor Source
-----------------------------------------------------------------------

if exists ( select 1 from tb_RatePlan where RatePlanID = @RatePlanID and DirectionID = 1 ) -- Inbound Rate Plan
Begin

		if exists (select 1 from UC_Commerce.dbo.tb_Source where sourcetypeid = -3 and rateplanID = @RatePlanID)
		Begin
			set @ErrorDescription = 'ERROR !!! Cannot delete Rate Plan as it is associated with a Customer Source'
			set @ResultFlag = 1
			Return 1
		End

End


if exists ( select 1 from tb_RatePlan where RatePlanID = @RatePlanID and DirectionID = 2 and ProductCataLogID = -4 ) -- Vendor Specific Rate Plan
Begin

		if exists (select 1 from UC_Commerce.dbo.tb_Source where sourcetypeid = -1 and rateplanID = @RatePlanID)
		Begin
			set @ErrorDescription = 'ERROR !!! Cannot delete Rate Plan as it is associated with a Vendor Source'
			set @ResultFlag = 1
			Return 1
		End

End
---------------------------------------------------------
-- Delete record from database for the rate plan
---------------------------------------------------------

Begin Try

	Delete from tb_RatePlan
	where RatePlanID = @RatePlanID


End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!! Deleting Rate Plan record.'+  ERROR_MESSAGE()
	set @ResultFlag = 1
	Return 1

End Catch

Return 0
GO
