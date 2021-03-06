USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSSendPrepaidThresholdAlertOnEmail]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Procedure [dbo].[SP_BSSendPrepaidThresholdAlertOnEmail]
(
	@AccountID int,
    @ThresholdType int,
	@CreditBalance Decimal(19,2),
	@ThresholdBalance Decimal(19,2)
)
As

Declare @EmailList varchar(2000),
        @Subject varchar(200),
		@Account varchar(60),
		@EmailBody varchar(3000),
		@UserName varchar(30),
		@LogFileName varchar(1000) = NULL

-------------------------------------------------------------
-- Get the account name for use in subject and message body
-------------------------------------------------------------
Select @Account = Account
from tb_Account
where AccountID = @AccountID

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

------------------------------------------------------------------------------------
-- Set the Subject of the message email indicatind which Threshold has been crossed
------------------------------------------------------------------------------------
if (@ThresholdType = 1)
	set @Subject = 'ALERT: Prepaid credit balance below Threshold 1 for account (' + @Account + ')' 

if (@ThresholdType = 2)
	set @Subject = 'ALERT: Prepaid credit balance below Threshold 2 for account (' + @Account + ')' 

set @Subject = @Subject + ' on ' + convert(varchar(20) , getdate(), 120)

-------------------------------------------------------------------------
-- Set the body of the email message based on the Threshold Type
-------------------------------------------------------------------------
set @EmailBody = 'Kindly be informed that prepaid credit balance for account ' + '<b>' + @Account + '</b>' +
	            ' is ' + '<b>' + '<font color="red">'+ convert(varchar(20) , @CreditBalance) + '</font>' + '</b>' +
				' and its below the configured threshold of ' + '<b>' +  + '<font color="green">' + convert(varchar(20) , @ThresholdBalance) + '</font>'  + '</b>' + '.' + '<br><br>'

set @EmailBody = 'Hi All,' + '<br><br>' + @EmailBody

if (@ThresholdType = 2)
Begin

		set @EmailBody = @EmailBody + 'As preventive measure the incoming traffic for the account will be blocked.' + '<br><br>'

End

set @EmailBody = @EmailBody + 'This is an information alert and does not require any action from your end.'

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

return 0
GO
