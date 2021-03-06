USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSThresholdCheck]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[SP_BSThresholdCheck]
(

	@AccountID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output

)

AS 

DECLARE @CreditBalance Decimal(19,2)
DECLARE @BelowThreshold2Flag INT
DECLARE @BlockStatus INT
DECLARE @Threshold_1 Decimal(19,2)
DECLARE @Threshold_2 Decimal(19,2)
DECLARE @EntriesCount Int = 0
DECLARE @Alert_1 INT
DECLARE @Alert_2 INT

------------------------------------------------------------------------
-- Check to ensure that ACCOUNT ID is valid and exists in the system
------------------------------------------------------------------------
if not exists (select 1 from tb_Account where accountID = @AccountID )
Begin

	set @ErrorDescription = 'ERROR!!! Account ID does not exist in the system'
	set @ResultFlag = 1
	Return 1

End

----------------------------------------------------------------------------------
--1. Check the account credit balance (if Account is blocked do nothing and return)
----------------------------------------------------------------------------------

if exists (select 1 from tb_Trunk where TrunkTypeID <> 9 and AccountID = @AccountID and Flag & 64 = 0 ) -- One or more Unblocked trunks
	SET  @BlockStatus =  0
Else
	SET  @BlockStatus =  1
	
IF @BlockStatus = 0 -- UnBlocked Check
BEGIN 
		
	set @BelowThreshold2Flag = 0 -- 0 means its above threshold2  1 means its below Threshold2

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

	---------------------------------------------------------------
	-- Establish if the Credit balance is below the Threshold 2
	---------------------------------------------------------------
	set @CreditBalance = 999 -- For testing
	
	if exists (
				 select 1 
				 from tb_PrepaidThreshold 
				 where AccountID = @AccountID 
				 and convert(date , getdate()) between BeginDate and isnull(EndDate,  convert(date , getdate()))
			  )
	Begin

			Select @Threshold_2 = Threshold_2
			from tb_PrepaidThreshold 
			where AccountID = @AccountID 
			and convert(date , getdate()) between BeginDate and isnull(EndDate,  convert(date , getdate()))

			
			if (@CreditBalance < @Threshold_2)
			begin
				set @BelowThreshold2Flag = 1
				GOTO THRESHOLD_2_BLOCKING
			end
	End

	----------------------------------------------------------------------------------------------------
	--- 2. If the balance is above the thresholds, then go to Threshold table and delete any old entries
	----------------------------------------------------------------------------------------------------

		--------------------------
		--Get the threshold values
		--------------------------
		SELECT	@Threshold_1 = Threshold_1,
				@Threshold_2 = Threshold_2
		FROM tb_PrepaidThreshold
		WHERE AccountID = @AccountID 
		and getdate() between BeginDate and isnull(EndDate,getdate())

		------------------------------------------
		-- If no threshold are set, throw an error
		------------------------------------------

		IF (ISNULL(@Threshold_1,1) = 1) AND (ISNULL(@Threshold_2,1) = 1)
		BEGIN
			SET @ResultFlag = 1
			SET @ErrorDescription = 'Threshold values are not set'
			GOTO ENDPROCESS
		END

		----------------------------------------------------------------
		--If Creditbalance more than threshold 1 then expire both alerts
		----------------------------------------------------------------
		IF @CreditBalance > @Threshold_1

		BEGIN
			------------------------------------
			-- Mark the Active Entries to Expire
			------------------------------------
			UPDATE tb_ThresholdAlertTable
				SET AlertStatus = 0 -- Expired
				WHERE AccountID = @AccountID

			GOTO ENDPROCESS

		END

	----------------------------------------------------------
	--3. if the balance is between threshold 1 and threshold2:
	----------------------------------------------------------

	IF @CreditBalance < @Threshold_1 AND @CreditBalance > @Threshold_2 
	BEGIN			
		-----------------------------------------------------------------
		--	3.1 Check if any entry exists in Threshold table for Alert 1
		--	3.2 If no entry exists, throw the Alert 1 and create an entry
		-----------------------------------------------------------------
		if not exists(	
						select 1
						FROM tb_ThresholdAlertTable
						WHERE AccountID = @AccountID AND 
						AlertType = -1 AND -- Threshold 1 Flag
						AlertStatus = 1 -- Active 						
		)		
		BEGIN
			INSERT INTO tb_ThresholdAlertTable VALUES(@AccountID,@CreditBalance,-1,getdate(),1)
			GOTO ENDPROCESS
		END
		-------------------------------------------------
		-- Entry for Alert for threshold 1 already exists
		-------------------------------------------------		
		GOTO ENDPROCESS
	END

	THRESHOLD_2_BLOCKING:
	-----------------------------------------------
	--4. Check If the balance is below Threshold 2:
	-----------------------------------------------
	IF @CreditBalance < @Threshold_2
	BEGIN
		-------------------------------------------------------------------------------
		--	4.1 Create an entry in the Threshold table for Alert 2 if it doesn't exists
		-------------------------------------------------------------------------------
		if not exists(	
						Select 1
						FROM tb_ThresholdAlertTable
						WHERE AccountID = @AccountID AND 
						AlertType = -2 AND -- Threshold 2 Flag
						AlertStatus = 1 -- Active 
						-- If no entry exists, throw the Alert 2 and create an entry
			)			
		BEGIN
					INSERT INTO tb_ThresholdAlertTable VALUES (@AccountID,@CreditBalance,-2,getdate(),1)
		END
	
		--------------------------
		--	4.2 Block the account
		--------------------------
		
		Begin Try

					set @ErrorDescription = NULL
					set @ResultFlag = 0

					select 'Blocking Account'
					--EXEC	[dbo].[SP_BSCustomManageIncomingTrafficByAccount]
					--		@AccountID = @AccountID,
					--		@TaskFlag = 1, -- Blocking the Account
					--		@ReasonDesc = N'Account blocked due to low credit balance',
					--		@UserID = -1,
					--		@ErrorDescription = @ErrorDescription OUTPUT,
					--		@ResultFlag = @ResultFlag OUTPUT	
					if (@ResultFlag  = 1)
					Begin

							set @ErrorDescription = 'Error!!! While Account blocking. ' + @ErrorDescription
							GOTO ENDPROCESS

					End

		End Try

		Begin Catch
					set @ErrorDescription = 'Error!!! While Account blocking. ' + ERROR_MESSAGE()
					set @ResultFlag = 1
					GOTO ENDPROCESS
		End Catch
		
	END

END -- Main if

ENDPROCESS:
		IF @ResultFlag = 1 
			begin
				select 'End process'
				return 1
			end
		return 0 -- If Account already blocked
		
GO
