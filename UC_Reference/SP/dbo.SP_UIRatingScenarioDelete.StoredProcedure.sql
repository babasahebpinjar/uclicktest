USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRatingScenarioDelete]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRatingScenarioDelete]
(
	@RatingScenarioID int,
	@UserID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

--------------------------------------------------
-- Ensure that Rating Scenario ID is a valid value
--------------------------------------------------

if ( @RatingScenarioID is NULl )
Begin

	set @ErrorDescription = 'ERROR !!! Rating Scenario ID cannot be NULL'
	set @ResultFlag = 1
	Return 1

End

if not exists ( select 1 from tb_RatingScenario where RatingScenarioID = @RatingScenarioID )
Begin

	set @ErrorDescription = 'ERROR !!! Rating Scenario ID does not exist'
	set @ResultFlag = 1
	Return 1

End

----------------------------------------------------------------------------------------
-- Make sure to delete the Rating Scenario and all the corresponding Rating Settlements
----------------------------------------------------------------------------------------

Begin transaction DeleteRS

Begin Try

	Delete from tb_RatingSettlement
	where RatingScenarioID = @RatingScenarioID

	Delete from tb_RatingScenario
	where RatingScenarioID = @RatingScenarioID

End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!! Deleting records for Rating Scenario.'+ ERROR_MESSAGE()
	set @ResultFlag = 1
	Rollback transaction DeleteRS
	Return 1

End Catch

Commit Transaction DeleteRS

Return 0
GO
