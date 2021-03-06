USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSCollectorGetNamesOfFTPFiles]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_BSCollectorGetNamesOfFTPFiles]
(
    @FileNameTag varchar(100),
    @FTPSiteIPAddress varchar(255),
    @FTPSiteUsername varchar(255),
    @FTPSitePassword varchar(255),
    @WorkDirectory varchar(255),
    @FTPSiteDirectory varchar(500),
    @FTPExecutablePath varchar(500),
	@AbsoluteLogFilePath varchar(1000),
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

Declare @Command varchar(2000),
        @ErrorMsgStr varchar(500)

set @ErrorDescription = NULL
set @ResultFlag = 0

------------------------------------------
-- Extract the essential values for FTP
------------------------------------------

if ( right(@FTPExecutablePath , 1) <> '\')
	 set @FTPExecutablePath  = @FTPExecutablePath  + '\'

----------------------------------------------------
-- Connect to the FTP site to get the names of all
-- the files, which qualify for selection
---------------------------------------------------- 

----------------------------
-- Declare Work Variables
----------------------------

Declare @AbsoluteFilename varchar(500),
        @FTPFileName varchar(500),
        @FTPCmdFile varchar(255),
        @FTPCmdTbName varchar(255),
        @CommandLine varchar(255),
        @bcpServer Varchar(255),
        @Cmd varchar(1000),
        @FileExists int

DECLARE @Random INT
DECLARE @Upper INT
DECLARE @Lower INT
Declare @ProcessLogID int

SET @Lower = 1 ---- The lowest random number
SET @Upper = 999999 ---- The highest random number
SELECT @Random = ROUND(((@Upper - @Lower -1) * RAND() + @Lower), 0)
set @ProcessLogID = @Random 

---------------------------------------
-- Prepare to initiate the FTP process
---------------------------------------

Select  @bcpServer=@@ServerName

Begin Try

		---------------------------------------------------
		-- Create a unique table name, in case other FTP 
		-- requests are running
		---------------------------------------------------

		Select	@FTPCmdTbName	= 'TmpFTPCmdGetFileName'  +Ltrim(Str(@ProcessLogID))

		if ( right(@WorkDirectory , 1) <> '\')
			 set @WorkDirectory  = @WorkDirectory  + '\'

		SELECT	@FTPCmdFile = @WorkDirectory + @FTPCmdTbName + '.txt'
   
		if exists ( select 1 from sysobjects where name = @FTPCmdTbName and xtype = 'U' )
				   Exec('Drop table '+ @FTPCmdTbName )

		---------------------------------------------------
		-- Create the table that has the SFTP commands to be
		-- run in batch and insert commands in the table
		---------------------------------------------------

		EXEC	('CREATE	TABLE ' + @FTPCmdTbName + ' (Command	varchar(255) NULL) ')

		SELECT	@CommandLine = 'open ' + @FTPSiteIPAddress
		EXEC	('INSERT ' + @FTPCmdTbName + ' VALUES(' + ''''  + @CommandLine + '''' + ')' )

		SELECT	@CommandLine = 'cd ' + '"' + @FTPSiteDirectory + '"'
		EXEC	('INSERT ' + @FTPCmdTbName + ' VALUES(' + ''''  + @CommandLine + '''' + ')' )

		
		SELECT	@CommandLine = 'dir ' + @FileNameTag + '*'
		EXEC	('INSERT ' + @FTPCmdTbName + ' VALUES(' + ''''  + @CommandLine + '''' + ')' )


		SELECT	@CommandLine = 'bye ' 
		EXEC	('INSERT ' + @FTPCmdTbName + ' VALUES(' + ''''  + @CommandLine + '''' + ')' )

		------------------------------------------------
		-- Create the batch file for running the FTP
		-- commands
		------------------------------------------------

		SELECT 	@Cmd = 'bcp '+ db_name() +'.dbo.' + @FTPCmdTbName + ' out ' + 
				@FTPCmdFile + ' -S ' + @bcpServer + ' -T -c'
		print @cmd

		--Select 'Debug : Checking Temp table can pass data between procs' as status
		--select * from #tmpOutputGetLisOfCDRFiles

		delete from #tmpOutputGetLisOfMasterlogFiles

		Insert	#tmpOutputGetLisOfMasterlogFiles
		EXEC 	master..xp_cmdshell @Cmd

		-- Added the correct syntax for calling PSFTP
		SELECT 	@Cmd = 'echo y |'+ '"'+@FTPExecutablePath +'PSFTP"'+' -v -l '+@FTPSiteUsername+ ' -pw '+ @FTPSitePassword+ ' -b ' + @FTPCmdFile 
		print @Cmd
 
		delete from #tmpOutputGetLisOfMasterlogFiles

		Insert	#tmpOutputGetLisOfMasterlogFiles
		EXEC 	master..xp_cmdshell @Cmd

		--Select 'Debug : Checking list of CDR files in temp table' as status
		--Select * from  #tmpOutputGetLisOfCDRFiles

		-------------------------------------------------------
		-- Extract the names of the fies from the Temp Table
		------------------------------------------------------

		delete from #tmpOutputGetLisOfMasterlogFiles
		where rowdata is null

		delete from #tmpOutputGetLisOfMasterlogFiles
		where charindex(@FileNameTag , rowdata) = 0

		-- Added this clause, because if the FTP directory contains lot off files, then the buffer gets full
		-- and this message is received for a file

		delete from #tmpOutputGetLisOfMasterlogFiles
		where charindex('Sent EOF message' , rowdata) <> 0 

		update #tmpOutputGetLisOfMasterlogFiles
		set rowdata = SUBSTRING(rowdata , charindex(@FileNameTag , rowdata) , LEN(rowdata) )

		--Select 'Debug : Checking list of CDR files in temp table after deleting redundant data' as status
		--Select * from  #tmpOutputGetLisOfCDRFiles

End Try

Begin Catch

	       set @ErrorDescription = 'SP_BSCollectorGetNamesOfFTPFiles : '+ convert(varchar(30) ,getdate() , 120) +
	                        ' : ' + ' ERROR !!!! While getting name of files to FTP.'+ ERROR_MESSAGE()

           Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

		   set @ResultFlag = 1

		   GOTO ENDPROCESS		


End Catch


ENDPROCESS:
-----------------------------------------
-- Drop temp tables and delete Temp files
------------------------------------------

set @FileExists = 0

Exec master..xp_fileexist @FTPCmdFile , @FileExists output 

if ( @FileExists = 1 )
Begin

    set @cmd = 'Del ' + @FTPCmdFile 
    Exec master..xp_cmdshell @cmd 
		     

End

if exists ( select 1 from sysobjects where name = @FTPCmdTbName and xtype = 'U' )
           Exec('Drop table '+ @FTPCmdTbName )


return 0
GO
