USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIPrepaidThresholdDelete]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE Procedure [dbo].[SP_UIPrepaidThresholdDelete]
(
	@PrepaidThresholdID int,
	@UserID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ResultFlag = 0
set @ErrorDescription = NULL

----------------------------------------------------------------
-- Check if the ThresholdID exists in the system and is not NULL
----------------------------------------------------------------

if (@PrepaidThresholdID is NULL)
Begin

		set @ErrorDescription = 'ERROR !!! Prepaid ThresholdID cannot be a NULL value'
		set @ResultFlag = 1
		Return 1

End

if not exists (Select 1 from tb_PrepaidThreshold where PrepaidThresholdID = @PrepaidThresholdID)
Begin

		set @ErrorDescription = 'ERROR !!! Prepaid ThresholdID is not valid or does not exist in the system'
		set @ResultFlag = 1
		Return 1

End

----------------------------------------------------------------------
-- Get the existing dates for the Threshold Record being updated
----------------------------------------------------------------------
Declare @BeginDate datetime,
        @EndDate datetime,
		@AccountID int

Select @BeginDate = BeginDate,
	   @EndDate = EndDate,
	   @AccountID = AccountID
from tb_PrepaidThreshold
where PrepaidThresholdID = @PrepaidThresholdID

----------------------------------------------------------------------------
-- Only delete thresholds which are in the future or valid for current date
----------------------------------------------------------------------------

if (
		(@BeginDate >= convert(date , getdate()))
		and
		(isnull(@EndDate , @BeginDate) >= convert(date , getdate()))
   )
Begin

		Begin Try

			Delete from tb_PrepaidThreshold
			where PrepaidThresholdID = @PrepaidThresholdID

		End Try

		Begin Catch

			set @ErrorDescription = 'ERROR !!! Deleting Threshold record. '+ERROR_MESSAGE()
			set @ResultFlag = 1
			Return 1

		End Catch

End

Else
Begin

		set @ErrorDescription = 'ERROR !!! Cannot delete threshold record if its for past dates'
		set @ResultFlag = 1
		Return 1

End
GO
