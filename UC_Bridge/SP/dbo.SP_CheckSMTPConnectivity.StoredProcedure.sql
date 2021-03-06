USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_CheckSMTPConnectivity]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_CheckSMTPConnectivity]
(
	@ServerName varchar(100) ,
	@From varchar(300) ,
	@Passwd varchar(100),
	@Port int ,
	@SSL char(1),
	@ProxyServerName varchar(100),
	@ProxyServerPort varchar(10) ,
	@LicenseKey	varchar(100) 
)
As 
	
Declare @ExecFileName varchar(500),
		@cmd varchar(2000)

        		
-------------------------------------------------------------------
-- Get the name of executable file for sending email alert via SMTP
-------------------------------------------------------------------

select @ExecFileName = ConfigValue
from tb_config
where configname = 'CheckSMTPConnectivity'

-------------------------------------------------------
-- Get the default folder for the Perl executable
-------------------------------------------------------


set @cmd =   @ExecFileName + ' ' + 
			 '"' + @ServerName + '" "'  +  @From + '" "' +  @Passwd + '" "' + 
			 Case
					When @SSL = 'Y' Then 'true'
					When @SSL = 'N' then 'false'
	         End + 
		    '" "' + convert(varchar(20) ,@Port) +  '" ' +
			Case
				When @ProxyServerName is NULL then '""'
				Else '"' + @ProxyServerName + '"'
			End + ' '+
			Case
				When @ProxyServerPort is NULL then '""'
				Else '"' + @ProxyServerPort + '"' 
			End + ' ' +
			'"'+ @LicenseKey + '"'
					 
print @cmd	

Exec master..xp_cmdshell @cmd
				 

GO
