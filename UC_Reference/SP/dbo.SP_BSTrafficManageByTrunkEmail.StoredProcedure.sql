USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSTrafficManageByTrunkEmail]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_BSTrafficManageByTrunkEmail]
(
	@TrunkIDList nvarchar(max) ,
    @ReasonCode varchar(200),
	@TaskFlag int,
	@UserID int
)
As

Declare @EmailList varchar(2000),
        @Subject varchar(200),
		@Account varchar(60),
		@EmailBody nvarchar(max),
		@UserName varchar(30),
		@LogFileName varchar(1000) = NULL

----------------------------------------------
-- Get the list of trunks in the Trunk list
----------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempTrunkIDList') )
				Drop table #TempTrunkIDList

Create Table #TempTrunkIDList (TrunkID varchar(100) )


insert into #TempTrunkIDList
select * from FN_ParseValueList ( @TrunkIDList )

-------------------------------------------------------------
-- Get the details like Trunk Name , Account , Switch for the
-- trunk to display in the email body
-------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAllTrunkData') )
				Drop table #TempAllTrunkData

select '<tr>'+ 
	'<td style=''border: 1px solid #cccccc; padding:3px;''>'+ tbl2.Trunk + '</td>' +
	'<td style=''border: 1px solid #cccccc; padding:3px;''>'+ tbl3.Account + '</td>' +
	'<td style=''border: 1px solid #cccccc; padding:3px;''>'+ tbl4.Switch + '</td>' + '</tr>'
as EmailStr
into #TempAllTrunkData
from #TempTrunkIDList tbl1
inner join tb_trunk tbl2 on tbl1.TrunkID = tbl2.TrunkID
inner join tb_Account tbl3 on tbl2.AccountID = tbl3.AccountID
inner join tb_Switch tbl4 on tbl2.SwitchID = tbl4.SwitchID

--select * from #TempAllTrunkData

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
	set @Subject = 'ALERT: Unblocking incoming traffic for Trunk(s)' 
Else
	set @Subject = 'ALERT: Blocking incoming traffic for Trunk(s)'

set @Subject = @Subject + ' on ' + convert(varchar(20) , getdate(), 120)

-------------------------------------------------------------------------
-- Set the body of the email message based on the task being performed
-------------------------------------------------------------------------
if (@TaskFlag = 0)
Begin

	set @EmailBody = 'Kindly be informed that incoming traffic for following physical trunk(s) ' +
	                 ' has/have been ' + '<b>' + '<font color="green">'+'UNBLOCKED' + '</font>' + '</b>' + '<br>' +' by user  ' + '<b>' + @UserName + '</b>' + 
					 ' with the reason ' + '<b>' + @ReasonCode + '</b>' + ':' + '<br><br>'

End

Else
Begin

	set @EmailBody = 'Kindly be informed that incoming traffic for following physical trunk(s) ' +
	                 ' has/have been ' + '<b>' + '<font color="red">'+'BLOCKED' + '</font>' + '</b>' + '<br>' +' by user  ' + '<b>' + @UserName + '</b>' + 
					 ' with the reason ' + '<b>' + @ReasonCode + '</b>' + ':' + '<br><br>'

End

set @EmailBody = 'Hi All,' + '<br><br>' + @EmailBody

set @EmailBody = @EmailBody + 
				 '<table style=''font-family: sans-serif;border-collapse: collapse;width: 100%;''>'+
					'<tr>'+
						 '<th style=''border: 1px solid #cccccc;text-align: center; padding:3px;''>Trunk Name</th>'+
						 '<th style=''border: 1px solid #cccccc;text-align: center; padding:3px;''>Account</th>'+
						 '<th style=''border: 1px solid #cccccc;text-align: center; padding:3px;''>Switch</th>'+
					'</tr>'


-------------------------------------------------------------------
-- Open a cursor to read through all the trunks in the list and
-- add to the email message
-------------------------------------------------------------------

Declare @VarAlertMessage varchar(1000)

DECLARE db_cur_Prepare_Message CURSOR FOR
select EmailStr 
from #TempAllTrunkData

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

set @EmailBody = @EmailBody + '</table>'

set @EmailBody = @EmailBody + '<br><br>' +'This is an information alert and does not require any action from your end.'

--print @EmailBody

--select len(@EmailBody)

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

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempTrunkIDList') )
				Drop table #TempTrunkIDList

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAllTrunkData') )
				Drop table #TempAllTrunkData

return 0
GO
