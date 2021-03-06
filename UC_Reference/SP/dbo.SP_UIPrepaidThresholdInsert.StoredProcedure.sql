USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIPrepaidThresholdInsert]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_UIPrepaidThresholdInsert]
(
	@AccountID int,
	@Threshold_1 int,
	@Threshold_2 int,
	@BeginDate datetime,
	@EndDate datetime = NULL,
	@UserID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

----------------------------------------------
-- Check if the Account exists in the system
----------------------------------------------

if not exists (Select 1 from tb_Account where AccountID = @AccountID and Flag & 32 <> 32)
Begin

		set @ErrorDescription = 'ERROR !!! Account does not exist in the system or is inactive'
		set @ResultFlag = 1
		Return 1

End

----------------------------------------------------------------
-- Check to ensure that Threshold_1 and Threshold_2 are not NULL
----------------------------------------------------------------

if (@Threshold_1 is NULL or @Threshold_2 is NULL)
Begin

		set @ErrorDescription = 'ERROR !!! Threshold values cannot be NULL'
		set @ResultFlag = 1
		Return 1

End

------------------------------------------------------------------
-- Check to ensure that Threshold_2 is greater than Threshold_1
------------------------------------------------------------------

if (@Threshold_1 <= @Threshold_2)
Begin

		set @ErrorDescription = 'ERROR !!! Threshold for Alert 1 should be more than Threshold for Alert 2'
		set @ResultFlag = 1
		Return 1

End

--------------------------------------------------------------
-- Begin Date should be lesser than or equal to the End date 
--------------------------------------------------------------
if (@BeginDate > isnull(@EndDate, @BeginDate) )
Begin

		set @ErrorDescription = 'ERROR !!! Begin Date for the threhold should be lesser or equal to End Date'
		set @ResultFlag = 1
		Return 1

End

---------------------------------------------------------------------
-- Ensure that the new Threshold being created is not in the past
---------------------------------------------------------------------

if (@BeginDate < convert(date, getdate()))
Begin

		set @ErrorDescription = 'ERROR !!! Begin Date for the new threshold cannot be less than current date'
		set @ResultFlag = 1
		Return 1

End

if ( (@EndDate is not NULL) and (@EndDate < convert(date, getdate())) )
Begin

		set @ErrorDescription = 'ERROR !!! End Date for the new threshold cannot be less than current date'
		set @ResultFlag = 1
		Return 1

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

Exec  SP_BSCheckDateOverlap @BeginDate , @EndDate , @DateOverlapCheckFlag output

if ( @DateOverlapCheckFlag = 1 )
Begin

	set @ErrorDescription = 'ERROR !!! There exist Threshold(s) in the system having dates overlapping with the new threshold'
	set @ResultFlag = 1
	GOTO ENDPROCESS

End


--------------------------------------------------
-- Insert new threshold record into the system
--------------------------------------------------
Begin Try

		insert into tb_PrepaidThreshold
		(
			AccountID,
			Threshold_1,
			Threshold_2,
			BeginDate,
			EndDate,
			ModifiedByID,
			ModifiedDate
		)
		values
		(
			@AccountID,
			@Threshold_1,
			@Threshold_2,
			@BeginDate,
			@EndDate,
			@UserID,
			getdate()
		)

End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!! Inserting Threshold record into system. '+ERROR_MESSAGE()
	set @ResultFlag = 1
	GOTO ENDPROCESS

End Catch

ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDateOverlapCheck') )
	Drop table #TempDateOverlapCheck
GO
