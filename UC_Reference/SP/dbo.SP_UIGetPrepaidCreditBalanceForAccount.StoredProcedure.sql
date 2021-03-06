USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetPrepaidCreditBalanceForAccount]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_UIGetPrepaidCreditBalanceForAccount]
(
	@AccountID int,
	@CreditBalance Decimal(19,2) Output,
	@BelowThreshold2Flag int Output
)
As

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
-- All Payments - Past PRepaid Balance - Current Prepaid Balance
-----------------------------------------------------------------
set @CreditBalance =  @AccountReceivableBalance - @PastPrepaidBalance - @CurrentPrepaidBalance

---------------------------------------------------------------
-- Establish if the Credit balance is below the Threshold 2
---------------------------------------------------------------
Declare @Threshold_2 Decimal(19,2)

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

		--select 'Debug' , @Threshold_2 as Threshold_2

		if (@CreditBalance < @Threshold_2)
			set @BelowThreshold2Flag = 1

End

Return 0




       

GO
