USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_SendEmailAlerts]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_SendEmailAlerts]
(
	@To varchar(1000),
	@Subject varchar(500),
	@EmailBody varchar(max),
	@LogFileName varchar(1000) = NULL
	
)
--With Encryption
As

Declare @ServerName varchar(100),
		@From varchar(300),
		@Passwd varchar(100),
		@Port int,
		@SSL varchar(10),
		@ProxyServerName varchar(100),
		@ProxyServerPort int,
		@LicenseKey varchar(100)


if ( ( @LogFileName is not NULL ) and ( LEN(@LogFileName) = 0))	
		set @LogFileName = NULL
		
if (@LogFileName is NULL )
	set @LogFileName = 'NoFile'	
	
Declare @ExecFileName varchar(500),
		@cmd varchar(8000)
		
-----------------------------------------------------------
-- Get the outgoing SMTP settings from the database
-----------------------------------------------------------

Select 	@ServerName = servername,
        @From = AccountName,
        @Passwd = password,
        @Port = PortNumber,
		@SSL = 
		     Case
					When SSL = 1 then 'true'
					When SSL = 0 then 'false'
			 End,
        @ProxyServerName = ProxyServerName,
		@ProxyServerPort = ProxyServerPort
from tblOutgoingMailSettings
where status = 1

Select @LicenseKey = LicenseKey
from tblIncomingMailSettings
where status = 1
        		
-------------------------------------------------------------------
-- Get the name of executable file for sending email alert via SMTP
-------------------------------------------------------------------

select @ExecFileName = ConfigValue
from tb_config
where configname = 'SendAlertViaSMTP'

---------------------------------------------------------------------
-- Attach the Customer name as suffix to the email subject, so that
-- system knows for whom the alert has been generated
---------------------------------------------------------------------

Declare @CustomerName varchar(200)

Select @CustomerName = name
from tblClientMaster
where ID = 1

set @CustomerName = isnull(@CustomerName, '')

set @Subject = @CustomerName + ' : ' + @Subject

-----------------------------------------------------------------
--In scenarios where there is an attachment file, we need to
--add the text in the email subject to check the file for more
--details
-----------------------------------------------------------------

if ( @LogFileName <> 'NoFile')
Begin

		set @EmailBody = @EmailBody +
						 '<br><br>' +
						 '<b> Please check attached file for more details. </b>'

End

-------------------------------------------------------
-- Get the default folder for the Perl executable
-------------------------------------------------------

Declare @PerlExecutable varchar(500)

select @PerlExecutable = ConfigValue
from tb_config
where configname = 'PerlExecutable'

set @cmd = 'ECHO ? && '+'"' + @ExecFileName + '"' + ' '  +
           '"' + + @ServerName + '"' + ' '  +
		   '"' + @From + '"' + ' ' + 
		   '"' + @Passwd + '"' +  ' ' +
		   '"' + @SSL + '"' +  ' ' +
		   '"' + convert(varchar(20) , @Port) + '"' + ' '+
		   '"' + ISNULL(@ProxyServerName , '') + '"' + ' ' +
		   '"' + ISNULL(convert(varchar(10) ,@ProxyServerPort) , '') + '"' + ' ' +
		   '"' + @LicenseKey + '"' + ' ' +
		   '"' + @To + '"' + ' ' +
		   '"' + @Subject + '"' + ' ' +
		   '"' + @EmailBody + '"' + ' ' +
		   '"' + @LogFileName + '"' + ' '

		 					 					 

print @cmd

Exec master..xp_cmdshell @cmd
				 

GO
