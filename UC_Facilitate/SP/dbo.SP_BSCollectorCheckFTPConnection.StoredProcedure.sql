USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSCollectorCheckFTPConnection]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_BSCollectorCheckFTPConnection]
(
   @FTPSiteIPAddress varchar(255),
   @FTPSiteUsername varchar(255),
   @FTPSitePassword varchar(255),
   @WorkDirectory varchar(255),
   @FTPExecutablePath varchar(500),
   @FTPSiteDirectory varchar(500),
   @ResultFlag int Output
)
As

----------------------------
-- Declare Work Variables
----------------------------

Declare @FTPFileName varchar(500),
        @FTPCmdFile varchar(255),
        @FTPCmdTbName Varchar(255),
        @CommandLine varchar(255),
        @bcpServer Varchar(255),
        @Cmd varchar(1000),
	    @FileExists int

DECLARE @Random INT
DECLARE @Upper INT
DECLARE @Lower INT

SET @Lower = 1 ---- The lowest random number
SET @Upper = 999999 ---- The highest random number
SELECT @Random = ROUND(((@Upper - @Lower -1) * RAND() + @Lower), 0)

Declare @ProcessLogID int
set @ProcessLogID = @Random 

if ( right(@FTPExecutablePath , 1) <> '\')
	 set @FTPExecutablePath  = @FTPExecutablePath  + '\'

---------------------------------------
-- Prepare to initiate the FTP process
---------------------------------------

Select  @bcpServer=@@ServerName

---------------------------------------------------
-- Create a unique table name, in case other FTP 
-- requests are running
---------------------------------------------------

Select	@FTPCmdTbName	= 'TmpTestFTPCmd'  +Ltrim(Str(@ProcessLogID))

if ( right(@WorkDirectory , 1) <> '\')
     set @WorkDirectory  = @WorkDirectory  + '\'

SELECT	@FTPCmdFile = @WorkDirectory + @FTPCmdTbName + '.txt'

set @WorkDirectory  = left(@WorkDirectory , len(@WorkDirectory) -1)

if exists ( select 1 from sysobjects where name = @FTPCmdTbName and xtype = 'U' )
           Exec('Drop table '+ @FTPCmdTbName )

---------------------------------------------------
-- Create the table that has the FTP commands to be
-- run in batch and insert commands in the table
---------------------------------------------------

EXEC	('CREATE	TABLE ' + @FTPCmdTbName + ' (Command	varchar(255) NULL) ')

SELECT	@CommandLine = 'open ' + @FTPSiteIPAddress
EXEC	('INSERT ' + @FTPCmdTbName + ' VALUES(' + ''''  + @CommandLine + '''' + ')' )

SELECT	@CommandLine = 'cd ' + '"' + @FTPSiteDirectory + '"'
EXEC	('INSERT ' + @FTPCmdTbName + ' VALUES(' + ''''  + @CommandLine + '''' + ')' )

SELECT	@CommandLine = 'bye ' 
EXEC	('INSERT ' + @FTPCmdTbName + ' VALUES(' + ''''  + @CommandLine + '''' + ')' )

------------------------------------------------
-- Create the batch file for running the FTP
-- commands
------------------------------------------------

SELECT 	@Cmd = 'bcp '+ db_name() +'.dbo.' + @FTPCmdTbName + ' out ' + 
		@FTPCmdFile + ' -S' + @bcpServer + ' -T -c'
print @cmd

create table #tmpTestFTPOutput ( CommandOutput varchar(2000) )

Insert	#tmpTestFTPOutput 
EXEC 	master..xp_cmdshell @Cmd

-------------------------
-- Run the FTP command
-------------------------

-- Added the correct syntax for calling PSFTP
SELECT 	@Cmd = '"'+@FTPExecutablePath +'PSFTP"'+' -v -l '+@FTPSiteUsername+ ' -pw '+ @FTPSitePassword+ ' -b ' +   @FTPCmdFile 
print @Cmd
 
delete from #tmpTestFTPOutput 

Insert	#tmpTestFTPOutput 
EXEC 	master..xp_cmdshell @Cmd

--Debug Mode
--select *
--from #tmpTestFTPOutput

set @ResultFlag = 0


IF exists ( select 1 from #tmpTestFTPOutput where CommandOutput like '%Login failed%' )
     set @ResultFlag = 10

IF exists ( select 1 from #tmpTestFTPOutput where CommandOutput like '%Connection timed out%' )
     set @ResultFlag = 20

IF exists ( select 1 from #tmpTestFTPOutput where CommandOutput like '%Host does not exist%' )
     set @ResultFlag = 30

IF exists ( select 1 from #tmpTestFTPOutput where CommandOutput like '%Unable to authenticate%' )
     set @ResultFlag = 40

IF exists ( select 1 from #tmpTestFTPOutput where CommandOutput like '%Directory%failure%' )
     set @ResultFlag = 50

IF exists ( select 1 from #tmpTestFTPOutput where CommandOutput like '%no such file or directory%' )
	set @ResultFlag = 60

-----------------------------------------
-- Drop temp tables and delete Temp files
------------------------------------------

set @FileExists = 0

Exec master..xp_fileexist @FTPCmdFile , @FileExists output 

if ( @FileExists = 1 )
Begin

    set @cmd = 'Del ' + @FTPCmdFile
	 
    delete from #tmpTestFTPOutput 

    Insert into #tmpTestFTPOutput 
    Exec master..xp_cmdshell @cmd 
		     

End

ENDPROCESS:

------------------------------------------------------------
-- Drop all the temprary tables created during the process
------------------------------------------------------------

Drop	Table #tmpTestFTPOutput

if exists ( select 1 from sysobjects where name = @FTPCmdTbName and xtype = 'U' )
           Exec('Drop table '+ @FTPCmdTbName )

GO
