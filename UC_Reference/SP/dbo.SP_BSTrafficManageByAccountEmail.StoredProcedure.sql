USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSTrafficManageByAccountEmail]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_BSTrafficManageByAccountEmail]
(
	@AccountID int,
    @ReasonCode varchar(200),
	@TaskFlag int,
	@UserID int
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

-------------------------------------------------------------
-- Get the user details for use in the message body
-------------------------------------------------------------
select @UserName = name
from UC_Admin.dbo.tb_users
where UserID = @UserID

-----------------------------------------------
-- Get the email list from the configuration
-----------------------------------------------
Select @EmailList = configvalue
from UC_Admin.dbo.tb_Config
where Configname = 'NetworkIncomingTrafficBlockEmailList'
and AccessScopeID = -4 -- Reference Management

if (@EmailList is NULL) -- No Email List configured indicates that email notification doesnt need to be send
Begin

	GOTO ENDPROCESS

End

---------------------------------------------------------------------------
-- Set the Subject of the message email based on the Task being performed
---------------------------------------------------------------------------
if (@TaskFlag = 0)
	set @Subject = 'ALERT: Unblocking incoming traffic for account (' + @Account + ')' 
Else
	set @Subject = 'ALERT: Blocking incoming traffic for account (' + @Account + ')'

set @Subject = @Subject + ' on ' + convert(varchar(20) , getdate(), 120)

-------------------------------------------------------------------------
-- Set the body of the email message based on the task being performed
-------------------------------------------------------------------------
if (@TaskFlag = 0)
Begin

	set @EmailBody = 'Kindly be informed that incoming traffic for account ' + '<b>' + @Account + '</b>' +
	                 ' has been ' + '<b>' + '<font color="green">'+'UNBLOCKED' + '</font>' + '</b>' + '<br>' +' by user  ' + '<b>' + @UserName + '</b>' + 
					 ' with the reason ' + '<b>' + @ReasonCode + '</b>' + '.' + '<br><br>'

End

Else
Begin

	set @EmailBody = 'Kindly be informed that incoming traffic for account ' + '<b>' + @Account + '</b>' +
	                 ' has been ' + '<b>' + '<font color="red">'+'BLOCKED' + '</font>' + '</b>' + '<br>' + ' by user  ' + '<b>' + @UserName + '</b>' +
					 ' with the reason ' + '<b>' + @ReasonCode + '</b>' + '.' + '<br><br>'

End

set @EmailBody = 'Hi All,' + '<br><br>' + @EmailBody
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
