USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIPrepaidThresholdUpdate]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_UIPrepaidThresholdUpdate]
(
	@PrepaidThresholdID int,
	@EndDate datetime = NULL,
	@UserID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

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
Declare @OldBeginDate datetime,
        @OldEndDate datetime,
		@AccountID int

Select @OldBeginDate = BeginDate,
	   @OldEndDate = EndDate,
	   @AccountID = AccountID
from tb_PrepaidThreshold
where PrepaidThresholdID = @PrepaidThresholdID

--------------------------------------------------------------------
-- Old Begin Date should be lesser than or equal to the New End date 
--------------------------------------------------------------------
if (@OldBeginDate > isnull(@EndDate, @OldBeginDate) )
Begin

		set @ErrorDescription = 'ERROR !!! New End Date for the threshold should be greater or equal to Begin Date'
		set @ResultFlag = 1
		Return 1

End

----------------------------------------------------------
-- Cannot modify a threoshold record which is in the past
----------------------------------------------------------

if ( 
		@OldEndDate is not NULL
		and
		@OldBeginDate < convert(date , getdate())
		and
		@OldEndDate < convert(date , getdate())
	)
Begin

		set @ErrorDescription = 'ERROR !!! Cannot modify a threshold record for past period'
		set @ResultFlag = 1
		Return 1

End

------------------------------------------------------
-- Ensure that the new End Date is not in the past
------------------------------------------------------

-- For a Threshold record which is active for the current running date, the End date
-- can only be set to date greater than equal to current date - 1

if (
		convert(date , getdate()) between @OldBeginDate 
		and 
		isnull(@OldEndDate , convert(date , getdate()))

	) -- Threshold Record Active for Current Date
Begin

		if ( (@EndDate is not NULL) and (@EndDate < datediff(dd ,convert(date, getdate()),1)))
		Begin

				set @ErrorDescription = 'ERROR !!! End Date for currently active threshold record can only be set to current date - 1'
				set @ResultFlag = 1
				Return 1

		End

End

-- For a threshold record in the future, the end date has to be greater or equal to the future begin date

if (
     (@OldBeginDate > convert(date , getdate()))
	 and 
	 (isnull(@OldEndDate , @OldBeginDate) > convert(date , getdate()))
   ) -- Record in Future
Begin

	if (@OldBeginDate > isnull(@EndDate, @OldBeginDate) )
	Begin

			set @ErrorDescription = 'ERROR !!! New End Date for the threshold should be greater or equal to Begin Date for future Threshold record'
			set @ResultFlag = 1
			Return 1

	End

End

-----------------------------------------------------------------
-- Check to see that there are no overlapping thresholds in the 
-- system for the account
-----------------------------------------------------------------

Declare @DateOverlapCheckFlag int = 0

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDateOverlapCheck') )
	Drop table #TempDateOverlapCheck

create table #TempDateOverlapCheck 
(
	EntityName varchar(100),
	BeginDate datetime,
	EndDate datetime
)

insert into #TempDateOverlapCheck
select distinct PrepaidThresholdID , Begindate , EndDate
from tb_PrepaidThreshold
where accountid = @AccountID
and PrepaidThresholdID <> @PrepaidThresholdID

Exec SP_BSCheckDateOverlap @OldBeginDate , @EndDate , @DateOverlapCheckFlag output

if ( @DateOverlapCheckFlag = 1 )
Begin

	set @ErrorDescription = 'ERROR !!! There exist Threshold(s) in the system having dates overlapping. Please update End Date of Threshold record accordingly.'
	set @ResultFlag = 1
	GOTO ENDPROCESS

End


--------------------------------------------------
-- Update threshold record with new End Date
--------------------------------------------------
Begin Try

	update tb_PrepaidThreshold
	set EndDate = @EndDate,
		ModifiedByID = @UserID,
		ModifiedDate =  getdate()
	where PrepaidThresholdID = @PrepaidThresholdID

End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!! Updating Threshold record. '+ERROR_MESSAGE()
	set @ResultFlag = 1
	GOTO ENDPROCESS

End Catch

ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDateOverlapCheck') )
	Drop table #TempDateOverlapCheck
GO
