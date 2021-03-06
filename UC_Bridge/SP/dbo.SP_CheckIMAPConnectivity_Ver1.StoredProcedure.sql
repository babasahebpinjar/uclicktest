USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_CheckIMAPConnectivity_Ver1]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_CheckIMAPConnectivity_Ver1]
(
	@ServerName varchar(100),
	@From varchar(300),
	@Passwd varchar(100),
	@ListOfFolders varchar(2000) = NULL
)
--With Encryption
As

Declare @Port int,
	@SSL int



if ((@ListOfFolders is not null) and (LEN(@ListOfFolders) = 0))
	set @ListOfFolders = ''
	
if (@ListOfFolders is NULL)
	set @ListOfFolders = ''
	
Declare @ExecFileName varchar(500),
		@cmd varchar(2000)
		
-----------------------------------------------------------
-- Get the Incoming IMAP settings from the database
-----------------------------------------------------------

Select 	@Port = PortNumber,
        @SSL = SSL
from tblincomingMailSettings
        		
-------------------------------------------------------------------
-- Get the name of executable file for sending email alert via SMTP
-------------------------------------------------------------------

select @ExecFileName = ConfigValue
from tb_config
where configname = 'CheckIMAPConnectivity'

-------------------------------------------------------
-- Get the default folder for the Perl executable
-------------------------------------------------------

Declare @PerlExecutable varchar(500)

select @PerlExecutable = ConfigValue
from tb_config
where configname = 'PerlExecutable'

if (@PerlExecutable is not NULL)
Begin


		set @cmd = 'ECHO ? && '+'"'+@PerlExecutable+'"' + ' ' + '"' + @ExecFileName + '"' + ' ' + 
							 '"' + @ServerName + '"' + ' '  + 
							 '"' + @From + '"' + ' ' + 
							 '"' + @Passwd + '"' +  ' ' +
							 '"' + convert(varchar(20) ,@Port) + '"' +  ' ' +
							 '"' + convert(varchar(20) ,@SSL) + '"' +  ' ' +
							 '"' + @ListOfFolders + '"'		


End

Else
Begin


		set @cmd = 'perl ' + '"' + @ExecFileName + '"' + ' ' + 
							 '"' + @ServerName + '"' + ' '  + 
							 '"' + @From + '"' + ' ' + 
							 '"' + @Passwd + '"' +  ' ' +
							 '"' + convert(varchar(20) ,@Port) + '"' +  ' ' +
							 '"' + convert(varchar(20) ,@SSL) + '"' +  ' ' +
							 '"' + @ListOfFolders + '"'


End
			

					 					 					 					 					 

print @cmd	

Exec master..xp_cmdshell @cmd
				 
GO
