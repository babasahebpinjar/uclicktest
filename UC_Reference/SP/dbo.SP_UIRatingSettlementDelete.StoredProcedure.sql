USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRatingSettlementDelete]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRatingSettlementDelete]
(
	@RatingSettlementID int,
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

if ( @RatingSettlementID is NULl )
Begin

	set @ErrorDescription = 'ERROR !!! Rating Settlement ID cannot be NULL'
	set @ResultFlag = 1
	Return 1

End

if not exists ( select 1 from tb_RatingSettlement where RatingSettlementID = @RatingSettlementID )
Begin

	set @ErrorDescription = 'ERROR !!! Rating Settlement ID does not exist'
	set @ResultFlag = 1
	Return 1

End

---------------------------------------
-- Delete the rating settlement record
---------------------------------------
Begin Try

	Delete from tb_RatingSettlement
	where RatingSettlementID = @RatingSettlementID

End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!! Deleting Rating Settlement record.'+ ERROR_MESSAGE()
	set @ResultFlag = 1
	Return 1

End Catch

Return 0
GO
