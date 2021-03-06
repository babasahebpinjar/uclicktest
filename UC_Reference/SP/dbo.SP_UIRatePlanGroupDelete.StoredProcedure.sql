USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRatePlanGroupDelete]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRatePlanGroupDelete]
(
    @RatePlanGroupID int,
	@UserID int ,
	@ErrorDescription varchar(2000) output,
	@ResultFlag int output
)
As

set @ErrorDescription  = NULL
set @ResultFlag = 0

-------------------------------------------------------------
-- Check to ensure that the RatePlanGroupID is valid value
-------------------------------------------------------------

if ( @RatePlanGroupID is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Rate Plan Group ID cannot be NULL'
	set @ResultFlag = 1
	return 1

End


if not exists ( select 1 from tb_RatePlanGroup where RatePlanGroupID  = @RatePlanGroupID )
Begin

	set @ErrorDescription = 'ERROR !!! Rate Plan Group ID does not exist or is not valid'
	set @ResultFlag = 1
	return 1

End

----------------------------------------------------------------
--  Check if this rate plan is not assigned to any rate plan
----------------------------------------------------------------

if exists ( select 1 from tb_rateplan where RatePlanGroupID = @RatePlanGroupID )
Begin

	set @ErrorDescription = 'ERROR !!! Cannot delete rate plan group as it is assigned to one or more rate plan'
	set @ResultFlag = 1
	return 1

End

-----------------------------------------------------
-- Delete  tb_RatePlanGroup table
-----------------------------------------------------

Begin Try

		delete from tb_rateplangroup
		where rateplangroupid = @RatePlanGroupID

End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!! Deleting Rate Plan Group record.' + ERROR_MESSAGE()
	set @ResultFlag = 1
	return 1

End Catch
GO
