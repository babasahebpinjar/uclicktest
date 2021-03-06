USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSPrepaidTrafficUsageAlert_Old]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Procedure [dbo].[SP_BSPrepaidTrafficUsageAlert_Old]
As

Declare @EmailList varchar(2000),
        @Subject varchar(200),
		@Account varchar(60),
		@EmailBody varchar(3000),
		@LogFileName varchar(1000) = NULL
		
------------------------------------------------------
-- Find the period based on which we will extract 
-- balance from past and present schema
------------------------------------------------------

Declare @CurrPeriod int 
Declare @CurrRunDate date =  dateadd(mm , -1 ,convert(date ,substring(convert(varchar(10) , getdate(),120) , 1,7) + '-' + '01'))

set @CurrPeriod = convert(int,replace(convert(varchar(7) , @CurrRunDate , 120), '-' , ''))


-----------------------------------------------------------------------
-- Get the list of accounts that are prepaid for the current period
-----------------------------------------------------------------------
if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAccountIDList') )
				Drop table #TempAccountIDList

Select AccountID
into #TempAccountIDList
from tb_AccountMode
where AccountModeTypeID = -2
and Period  = convert(int ,replace(convert(varchar(7) , getdate() , 120), '-' , ''))

if not exists (select 1 from #TempAccountIDList)
	GOTO ENDPROCESS

-----------------------------------------------------------------------------
-- Create tenmp table to hold all the balance information for each account
-----------------------------------------------------------------------------
if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAccountBalance') )
				Drop table #TempAccountBalance


create table #TempAccountBalance
(
	AccountID int,
	PastBalance Decimal(19,2),
	CurrentBalance Decimal(19,2),
	AccountReceivable Decimal(19,2),
	NetCreditBalance Decimal(19,2)
)

insert into #TempAccountBalance
select AccountID , 0 ,0 ,0,0
from #TempAccountIDList

--select * from #TempAccountBalance

----------------------------
-- Past Period Balance
----------------------------

update tbl1
set PastBalance = tbl2.Amount
from #TempAccountBalance tbl1 
inner join 
(
	Select AccountID , convert(Decimal(19,2) ,isnull(sum(Amount),0)) as Amount
	from ReportServer.UC_Report.dbo.tb_PrepaidPastBalance
	where Period < @CurrPeriod
	group by AccountID

)tbl2 on tbl1.AccountID = tbl2.AccountID

----------------------------
-- Current Period Balance
----------------------------

update tbl1
set CurrentBalance = tbl2.Amount
from #TempAccountBalance tbl1 
inner join 
(
	select AccountID ,convert(Decimal(19,2) ,isnull(sum(Amount),0)) as Amount
	from ReportServer.UC_Report.dbo.tb_PrepaidCurrentBalance
	where convert(int,replace(convert(varchar(7) , CallDate , 120), '-' , '')) >= @CurrPeriod
	Group by AccountID

) tbl2 on tbl1.AccountID = tbl2.AccountID

---------------------------------
-- Account Receivable Balance
---------------------------------

update tbl1
set AccountReceivable = tbl2.Amount
from #TempAccountBalance tbl1 
inner join 
(
	select AccountID ,convert(Decimal(19,2) ,isnull(sum(Amount),0)) as Amount
	from tb_AccountReceivable
	Group By AccountID

) tbl2 on tbl1.AccountID = tbl2.AccountID


-----------------------------------------------------------------
-- Set the Credit Balance as :
-- All Payments - Past Prepaid Balance - Current Prepaid Balance
-----------------------------------------------------------------

update #TempAccountBalance
set NetCreditBalance = AccountReceivable - PastBalance - CurrentBalance


-----------------------------------------------
-- Get the email list from the configuration
-----------------------------------------------
Select @EmailList = configvalue
from UC_Admin.dbo.tb_Config
where Configname = 'PrepaidThresholdAlertEmailList'
and AccessScopeID = -4 -- Reference Management

if (@EmailList is NULL) -- No Email List configured indicates that email notification doesnt need to be send
Begin

	GOTO ENDPROCESS

End

---------------------------------------------
-- Set the Subject of the message email
---------------------------------------------

set @Subject = 'ALERT: Prepaid Account(s) Traffic Utilization' 
set @Subject = @Subject + ' on ' + convert(varchar(20) , getdate(), 120)

------------------------------------
-- Set the body of the email message
-------------------------------------

set @EmailBody = 'Published below is the traffic utilization for active prepaid accounts:' + '<br><br>'
set @EmailBody = 'Hi All,' + '<br><br>' + @EmailBody

Declare @VarAlertMessage varchar(1000)

DECLARE db_cur_Prepare_Message CURSOR FOR
select '<p style="margin-left:40px"><I>The Credit balance for account <b>'+  acc.Account + '</b> is ' + 
	   Case
			When bal.NetCreditBalance < 0 Then '<b>' + '<font color="red">'+ convert(varchar(20), bal.NetCreditBalance) + '</font>' +'</b> '
			Else '<b>' + '<font color="green">'+ convert(varchar(20), bal.NetCreditBalance) + '</font>' + '</b> '
	   End +
	   Case
	        -- No payments have been made but traffic has been recorded
			When AccountReceivable = 0 and (PastBalance + CurrentBalance) > 0 then ' and traffic has been recorded without any credit (payments)'
			When AccountReceivable = 0 and (PastBalance + CurrentBalance) = 0 then ' and no traffic or credit(payments) have been recorded.'
			When AccountReceivable <> 0  then  ' and has utilized <b>' + 
			                                    convert(varchar(20), convert(Decimal(19,2) ,((PastBalance + CurrentBalance) * 100)/AccountReceivable)) + ' percent </b> of total credit.'
	   End + '</I></p>' 
from #TempAccountBalance bal
inner join tb_Account acc on bal.AccountID = acc.AccountID

OPEN db_cur_Prepare_Message
FETCH NEXT FROM db_cur_Prepare_Message
INTO @VarAlertMessage 

While @@FETCH_STATUS = 0
BEGIN

        set @EmailBody = @EmailBody + @VarAlertMessage 

		FETCH NEXT FROM db_cur_Prepare_Message
		INTO @VarAlertMessage   		 

END

CLOSE db_cur_Prepare_Message
DEALLOCATE db_cur_Prepare_Message

set @EmailBody = @EmailBody + '<br>' +'This is an information alert and does not require any action from your end.'

-----------------------------------------------------------------------------
-- Set the Log File Name to No file to indicate that there is no attachment
-----------------------------------------------------------------------------
if (@LogFileName is NULL )
	set @LogFileName = 'NoFile'

-----------------------------------------------
-- Call the procedure to send the email alert
-----------------------------------------------

Exec BRIDGESERVER.UC_Bridge.dbo.SP_SendEmailAlerts @EmailList , @Subject , @EmailBody , @LogFileName

ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAccountIDList') )
				Drop table #TempAccountIDList

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAccountBalance') )
				Drop table #TempAccountBalance

Return 0




       

GO
