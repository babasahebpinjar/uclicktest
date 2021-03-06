USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSPrepaidThresholdCheck]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


Create PROCEDURE [dbo].[SP_BSPrepaidThresholdCheck]
(

	@AccountID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output

)

AS 

set @ResultFlag = 0
set @ErrorDescription = NULL

DECLARE @CreditBalance Decimal(19,2),
        @BlockStatus int,
		@Threshold_1 Decimal(19,2),
		@Threshold_2 Decimal(19,2)

------------------------------------------------------------------------
-- Check to ensure that ACCOUNT ID is valid and exists in the system
------------------------------------------------------------------------
if not exists (select 1 from tb_Account where accountID = @AccountID )
Begin

	set @ErrorDescription = 'ERROR!!! Account ID does not exist in the system'
	set @ResultFlag = 1
	GOTO ENDPROCESS

End

----------------------------------------------------------------------------------
--Check if the account is blocked or not. Inc ase the account is blocked, we dont
-- need to do any
----------------------------------------------------------------------------------

if exists (select 1 from tb_Trunk where TrunkTypeID <> 9 and AccountID = @AccountID and Flag & 64 = 0 ) -- One or more Unblocked trunks
	set  @BlockStatus =  0
Else
	set  @BlockStatus =  1

if (@BlockStatus = 1)
	GOTO ENDPROCESS

----------------------------------------------------------------
-- For an unblocked account, get the current credit balance
----------------------------------------------------------------
Declare @PastPrepaidBalance Decimal(19,2),
		@CurrentPrepaidBalance Decimal(19,2),
		@AccountReceivableBalance Decimal(19,2)

------------------------------------------------------
-- Find the period based on which we will extract 
-- balance from past and present schema
------------------------------------------------------

Declare @CurrPeriod int 
Declare @CurrRunDate date =  dateadd(mm , -1 ,convert(date ,substring(convert(varchar(10) , getdate(),120) , 1,7) + '-' + '01'))

set @CurrPeriod = convert(int,replace(convert(varchar(7) , @CurrRunDate , 120), '-' , ''))

----------------------------
-- Past Period Balance
----------------------------

select @PastPrepaidBalance = convert(Decimal(19,2) ,isnull(sum(Amount),0))
from ReportServer.UC_Report.dbo.tb_PrepaidPastBalance
where accountID = @AccountID
and Period < @CurrPeriod

----------------------------
-- Past Period Balance
----------------------------

select @CurrentPrepaidBalance = convert(Decimal(19,2) ,isnull(sum(Amount),0))
from ReportServer.UC_Report.dbo.tb_PrepaidCurrentBalance
where accountID = @AccountID
and convert(int,replace(convert(varchar(7) , CallDate , 120), '-' , '')) >= @CurrPeriod

---------------------------------
-- Account Receivable Balance
---------------------------------

select @AccountReceivableBalance = convert(DEcimal(19,2) ,isnull(sum(Amount),0))
from tb_AccountReceivable
where AccountID = @AccountID


-----------------------------------------------------------------
-- Set the Credit Balance as :
-- All Payments - Past Prepaid Balance - Current Prepaid Balance
-----------------------------------------------------------------
set @CreditBalance =  @AccountReceivableBalance - @PastPrepaidBalance - @CurrentPrepaidBalance


-------------------------------------------------------------
-- Get the Threshold 1 and Threshold 2 amounts for the account
-- as per current date
-------------------------------------------------------------
-- In case there are no Threholds Active for the current data,
-- then exit
-------------------------------------------------------------

if exists (
				select 1 
				from tb_PrepaidThreshold 
				where AccountID = @AccountID 
				and convert(date , getdate()) between BeginDate and isnull(EndDate,  convert(date , getdate()))
			)
Begin

		Select	@Threshold_1 = Threshold_1,
				@Threshold_2 = Threshold_2
		From tb_PrepaidThreshold
		Where AccountID = @AccountID 
		and getdate() between BeginDate and isnull(EndDate,getdate())

End

Else
Begin

	GOTO ENDPROCESS

End

-------------------------------------------------------------------------------
-- Check if Credit Balance is above and equal to Threshold 1. In this case
-- expire all the existing alert records in the schema and exit
-------------------------------------------------------------------------------

if (@CreditBalance >= @Threshold_1)
Begin

		---------------------------------------------------
		-- Expire All Active Alerts and exit the program
		---------------------------------------------------

		Update tb_PrepaidThresholdAlert
		set AlertStatusID = 0 -- Expired
		where AccountID = @AccountID
		and AlertStatusID = 1 -- Active

		GOTO ENDPROCESS

End


--------------------------------------------------------------------------------
-- Check if Credit Balance is less than Threshold 1 and greater than Threshold 2
-- Create an active entry in the Threhold Alert Schema for the Alert incase 
-- entry does not exist
-- Send an email to conerned users regarding credit balance going below Threshold 1
--------------------------------------------------------------------------------

if ( (@CreditBalance < @Threshold_1) and (@CreditBalance >= @Threshold_2) )
Begin

	if not exists ( 
					Select 1 
					from tb_PrepaidThresholdAlert 
					Where AccountID = @AccountID 
					and AlertTypeID = -1 -- Threshold 1 Alert
					and AlertStatusID = 1 -- Active
				  )
	Begin

			--------------------------------------------------------
			-- Create an entry for Threhold 1 Alert in the schema
			--------------------------------------------------------

			Insert into  tb_PrepaidThresholdAlert
			(
				AccountID,
				CreditBalance,
				ThresholdAmount,
				AlertTypeID,
				AlertDate,
				AlertStatusID
			)
			values
			(
				@AccountID,
				@CreditBalance,
				@Threshold_1,
				-1,
				getdate(),
				1
			)

			------------------------------------------------------------
			-- Send an Alert email to the concerned forum regarding the
			-- alert
			------------------------------------------------------------

			Exec SP_BSSendPrepaidThresholdAlertOnEmail @AccountID,
													   1 , -- Threshold 1
													   @CreditBalance,
													   @Threshold_1

	End

	GOTO ENDPROCESS

End


-----------------------------------------------------------------
-- if credit Balance is below Threshold 2 then do the following:
-- 1. Create an entry in Alert schema for Threshold 2
-- 2. Send an email alert to all users
-- 3. Block the account
-----------------------------------------------------------------

if ( @CreditBalance < @Threshold_2)
Begin

	if not exists ( 
					Select 1 
					from tb_PrepaidThresholdAlert 
					Where AccountID = @AccountID 
					and AlertTypeID = -2 -- Threshold 1 Alert
					and AlertStatusID = 1 -- Active
				  )
	Begin

			--------------------------------------------------------
			-- Create an entry for Threhold 1 Alert in the schema
			--------------------------------------------------------

			Insert into  tb_PrepaidThresholdAlert
			(
				AccountID,
				CreditBalance,
				ThresholdAmount,
				AlertTypeID,
				AlertDate,
				AlertStatusID
			)
			values
			(
				@AccountID,
				@CreditBalance,
				@Threshold_2,
				-2,
				getdate(),
				1
			)

			------------------------------------------------------------
			-- Send an Alert email to the concerned forum regarding the
			-- alert
			------------------------------------------------------------

			Exec SP_BSSendPrepaidThresholdAlertOnEmail @AccountID,
													   2 , -- Threshold 2
													   @CreditBalance,
													   @Threshold_2
	End

	-----------------------------------------------
	-- Block the incoming traffic for the account
	----------------------------------------------- 

	Begin Try

				set @ErrorDescription = NULL
				set @ResultFlag = 0

				EXEC	SP_BSCustomManageIncomingTrafficByAccountMain
						@AccountID = @AccountID,
						@TaskFlag = 1, -- Blocking the Account
						@ReasonDesc = N'Account blocked due to low credit balance',
						@UserID = -1,
						@ErrorDescription = @ErrorDescription OUTPUT,
						@ResultFlag = @ResultFlag OUTPUT
					
				if (@ResultFlag  = 1)
				Begin

						set @ErrorDescription = 'Error!!! While blocking account due to low credit balance. ' + @ErrorDescription
						GOTO ENDPROCESS

				End

	End Try

	Begin Catch
				set @ErrorDescription = 'Error!!! While blocking account due to low credit balance. ' + ERROR_MESSAGE()
				set @ResultFlag = 1
				GOTO ENDPROCESS
	End Catch

End

ENDPROCESS:

if @ResultFlag = 1 
	Return 1
Else
	Return 0


		
GO
