USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSCollectorExportMasterlogFiles]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSCollectorExportMasterlogFiles]
(
	@FTPSiteIPAddress varchar(1000), 
	@FTPSiteUSerName varchar(1000),
	@FTPSitePassword varchar(1000), 
	@WorkDirectory varchar(1000),
	@FTPSiteDirectory varchar(1000), 
	@FTPExecutablePath varchar(1000), 
	@CompressionExtension varchar(1000) ,
	@MasterlogExtensionPartOfOriginalFile int,
	@MasterlogFileExtension varchar(1000),
	@UnCompressExecutablePath varchar(1000) ,
	@OutputFolderPath varchar(100),
	@AbsoluteLogFilePath varchar(1000),
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As


set @ErrorDescription = NULL
set @ResultFlag = 0

----------------------------------------------------------
-- Declare parameters to create a unique Process Log ID
----------------------------------------------------------


Declare @Random int,
        @Upper int,
        @Lower int,
        @ProcessLogID int

set  @Lower = 1 ---- The lowest random number
set  @Upper = 999999 ---- The highest random number
select @Random = ROUND(((@Upper - @Lower -1) * RAND() + @Lower), 0)
set @ProcessLogID = @Random 

---------------------------------------------------------------------------
-- Declare variables for building the name of the Masterlog and check sum files
---------------------------------------------------------------------------

Declare @CompressMasterlogFileName varchar(500),
        @MasterlogFileNameWithoutExtension varchar(500),
		@MasterlogFileName varchar(500),
		@MasterlogFileNameFullPath varchar(1000),
		@IntermediateFileNameFullPath varchar(1000),
        @CompressMasterlogFileNameFullPath varchar(1000),
		@MasterlogFileExportDirectory varchar(1000),
		@bcpServer Varchar(255),
		@FTPCmdTbName varchar(255),
		@FTPCmdFile varchar(100),
		@FileExists int,
		@cmd varchar(2000),
		@CommandLine varchar(2000),
		@TotalFilesTransferred int = 0,
		@FileDetails varchar(1000),
		@FileTimeStamp varchar(200),
		@CompressedFileSize varchar(200),
		@MasterlogFileSize varchar(200),
		@Foldername varchar(200),
		@PathExists BIT,
		@BaseOutputFolderPath varchar(100)

if ( right(@WorkDirectory , 1) = '\')
	set @MasterlogFileExportDirectory  = left(@WorkDirectory, len(@WorkDirectory) -1 )
else 
	set @MasterlogFileExportDirectory  = @WorkDirectory

if ( right(@WorkDirectory , 1) <> '\')
	set @WorkDirectory  = @WorkDirectory  + '\'

if ( right(@FTPExecutablePath , 1) <> '\')
	set @FTPExecutablePath  = @FTPExecutablePath  + '\'

if ( right(@OutputFolderPath , 1) <> '\')
	set @OutputFolderPath  = @OutputFolderPath  + '\'

set @BaseOutputFolderPath = @OutputFolderPath
-----------------------------------------------------------------------------
-- Delibrately hard coded to 100 files because dont want the collector process 
-- to run for too long. There have been instances,when the unzip process tends
-- to hang and locks the compress file also
------------------------------------------------------------------------------

DECLARE db_cur_get_Masterlog_Files CURSOR FOR
select top 100 rowdata from #tmpOutputGetLisOfMasterlogFiles

OPEN db_cur_get_Masterlog_Files
FETCH NEXT FROM db_cur_get_Masterlog_Files
INTO @CompressMasterlogFileName 

While @@FETCH_STATUS = 0
BEGIN

        Begin Try

				-------------------------------------------------------------
				-- Get a unique Process Log ID for creating temp FTP tables
				-------------------------------------------------------------

				set @Random = ROUND(((@Upper - @Lower -1) * RAND() + @Lower), 0)
				set @ProcessLogID = @Random 

				--------------------------------------------------------------------
				-- Perform all the essential steps to FTP the Masterlog and Checksum files
				--------------------------------------------------------------------

				Select  @bcpServer=@@ServerName

				if (@MasterlogExtensionPartOfOriginalFile = 1)
				Begin

					set @MasterlogFileNameWithoutExtension = substring(@CompressMasterlogFileName , 1  , len(@CompressMasterlogFileName) - len(@CompressionExtension) - len(@MasterlogFileExtension))
					set @MasterlogFileName = substring(@CompressMasterlogFileName , 1  , len(@CompressMasterlogFileName) - len(@CompressionExtension))

				End

				else
				Begin

					set @MasterlogFileNameWithoutExtension = substring(@CompressMasterlogFileName , 1  , len(@CompressMasterlogFileName) - len(@CompressionExtension))
					set @MasterlogFileName = substring(@CompressMasterlogFileName , 1  , len(@CompressMasterlogFileName) - len(@CompressionExtension)) + @MasterlogFileExtension

				End

				set @OutputFolderPath = @BaseOutputFolderPath
				
				set @Foldername = SUBSTRING(@MasterlogFileNameWithoutExtension,11,8) 

				print @Foldername
				
				set @PathExists = 0
						
				EXECUTE @PathExists = SP_BSCheckPathExists @OutputFolderPath,@Foldername
				
				print @PathExists


				print @OutputFolderPath


				IF (@PathExists <> 1) -- Path Doesnt Exists
				BEGIN

				set @cmd = 'mkdir ' + @OutputFolderPath + @Foldername

				Exec master..xp_cmdshell @cmd
								
				END

				
				set @OutputFolderPath = @OutputFolderPath + @Foldername

				

				if ( right(@OutputFolderPath , 1) <> '\')
					
					set @OutputFolderPath  = @OutputFolderPath  + '\'
				
				print @OutputFolderPath


				set @IntermediateFileNameFullPath = @OutputFolderPath + @MasterlogFileNameWithoutExtension + '.Temp'

				print @IntermediateFileNameFullPath


				set @CompressMasterlogFileNameFullPath = @WorkDirectory + @CompressMasterlogFileName

				--Select 'Debug: Publish all the different file names' as status
				--Select @MasterlogFileNameWithoutExtension as MasterlogFileNameWithoutExtension,
				--	   @MasterlogFileName as MasterlogFileName,
				--	   @IntermediateFileNameFullPath as IntermediateFileNameFullPath,
				--	   @CompressMasterlogFileNameFullPath as CompressMasterlogFileNameFullPath


				--------------------------------------------------------------------------------
				-- Delete any previous instance of the Compressed Masterlog and Check sum file from 
				-- the working directory
				-------------------------------------------------------------------------------

				set @FileExists = 0

				Exec master..xp_fileexist @CompressMasterlogFileNameFullPath , @FileExists output 

				if ( @FileExists = 1 )
				Begin

					set @cmd = 'Del ' + @CompressMasterlogFileNameFullPath 
					Exec master..xp_cmdshell @cmd 
				     
				End


				---------------------------------------------------
				-- Create a unique table name, in case other FTP 
				-- requests are running
				---------------------------------------------------

				set	@FTPCmdTbName	= 'TmpFTPCmd'  +Ltrim(Str(@ProcessLogID))

				set	@FTPCmdFile = @WorkDirectory + @FTPCmdTbName + '.txt'

				--------------------------------------------------------------------
				-- Drop any previous existence of the FTP commnad table and File
				-------------------------------------------------------------------
				
				if exists ( select 1 from sysobjects where name = @FTPCmdTbName and xtype = 'U' )
						   Exec('Drop table '+ @FTPCmdTbName )

				set @FileExists = 0

				Exec master..xp_fileexist @FTPCmdFile , @FileExists output 

				if ( @FileExists = 1 )
				Begin

					set @cmd = 'Del ' + @FTPCmdFile 
					Exec master..xp_cmdshell @cmd 
				     
				End

                -------------------------------------------------------------------------
				-- Build the command(s) to FTP the files into the working Directory
				-------------------------------------------------------------------------

				EXEC	('CREATE	TABLE ' + @FTPCmdTbName + ' (Command	varchar(255) NULL) ')

				SELECT	@CommandLine = 'open ' + @FTPSiteIPAddress
				EXEC	('INSERT ' + @FTPCmdTbName + ' VALUES(' + ''''  + @CommandLine + '''' + ')' )

				SELECT	@CommandLine = 'cd ' + @FTPSiteDirectory 
				EXEC	('INSERT ' + @FTPCmdTbName + ' VALUES(' + ''''  + @CommandLine + '''' + ')' )

				SELECT	@CommandLine = 'lcd ' + @MasterlogFileExportDirectory 
				EXEC	('INSERT ' + @FTPCmdTbName + ' VALUES(' + ''''  + @CommandLine + '''' + ')' )
				
				SELECT	@CommandLine = 'get ' + @CompressMasterlogFileName
				EXEC	('INSERT ' + @FTPCmdTbName + ' VALUES(' + ''''  + @CommandLine + '''' + ')' )
				
				SELECT	@CommandLine = 'bye ' 
				EXEC	('INSERT ' + @FTPCmdTbName + ' VALUES(' + ''''  + @CommandLine + '''' + ')' )

				------------------------------------------------
				-- Create the batch file for running the FTP
				-- commands
				------------------------------------------------

				SELECT 	@cmd = 'bcp '+ db_name() +'.dbo.' + @FTPCmdTbName + ' out ' + 
						@FTPCmdFile + ' -S' + @bcpServer + ' -T -c'

				--print @cmd

				EXEC 	master..xp_cmdshell @Cmd

				-------------------------
				-- Run the FTP command
				-------------------------

				-- Added the correct syntax for calling PSFTP

				SELECT 	@cmd = '"'+@FTPExecutablePath +'PSFTP"'+' -v -l '+@FTPSiteUsername+ ' -pw '+ @FTPSitePassword+ ' -b ' + @FTPCmdFile 

				--print @Cmd

				EXEC 	master..xp_cmdshell @cmd			
		
		End Try
		
		Begin Catch

				set @ErrorDescription = 'SP_BSCollectorExportMasterlogFiles : '+ convert(varchar(30) ,getdate() , 120) +
										' : ' + ' ERROR !!! Performing FTP for Masterlog file : ' + @MasterlogFileNameWithoutExtension + ' . ' + ERROR_MESSAGE()
				Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

				if exists ( select 1 from sysobjects where name = @FTPCmdTbName and xtype = 'U' )
						   Exec('Drop table '+ @FTPCmdTbName )

				set @FileExists = 0

				Exec master..xp_fileexist @FTPCmdFile , @FileExists output 

				if ( @FileExists = 1 )
				Begin

					set @cmd = 'Del ' + @FTPCmdFile 
					Exec master..xp_cmdshell @cmd 
				     
				End

				set @ResultFlag = 1

				CLOSE db_cur_get_Masterlog_Files
				DEALLOCATE db_cur_get_Masterlog_Files

				GOTO ENDPROCESS
		
		End Catch 

		----------------------------------------------------------------------
		-- Remove any instance of the FTP command table and file post
		-- completion of FTP
		----------------------------------------------------------------------

		if exists ( select 1 from sysobjects where name = @FTPCmdTbName and xtype = 'U' )
					Exec('Drop table '+ @FTPCmdTbName )

		set @FileExists = 0

		Exec master..xp_fileexist @FTPCmdFile , @FileExists output 

		if ( @FileExists = 1 )
		Begin

			set @cmd = 'Del ' + @FTPCmdFile 
			Exec master..xp_cmdshell @cmd 
				     
		End


		--------------------------------------------------------------------------------
		-- Check to confirm that compress file has have been FTP successfully
		--------------------------------------------------------------------------------

		set @FileExists = 0

		Exec master..xp_fileexist @CompressMasterlogFileNameFullPath , @FileExists output

		--------------------------------------------------------------------------------
		-- Publish an error message in the log file in case both files are not exported
		--------------------------------------------------------------------------------

        if ( @FileExists <> 1 )
		Begin
		 
				set @ErrorDescription = 'SP_BSCollectorExportMasterlogFiles : '+ convert(varchar(30) ,getdate() , 120) +
										' : ' + ' ERROR !!! Compressesd Masterlog file: '+ @CompressMasterlogFileName + ' has not been exported'
				
				Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

				GOTO PROCESSNEXTFILE

		End

		--------------------------------------------------------------
		-- Get the statistics for the compressed file post export
		--------------------------------------------------------------

		Exec SP_BSMasterlogCollectorGetFileDetails @CompressMasterlogFileName , @CompressMasterlogFileNameFullPath , @FileDetails Output

		set @FileTimeStamp = substring(@FileDetails,1,20)
		set @CompressedFileSize = substring(@FileDetails,21,len(@FileDetails))

		--Select 'Debug: Publish File time stamp and size for Compress File' as status
		--select @FileTimeStamp as FileTimeStamp,
		--	   @CompressedFileSize as CompressedFileSize,
		--	   @CompressMasterlogFileName as CompressMasterlogFileName

        ---------------------------------------------------------------
		-- Uncompress the Masterlog file to extract the original Masterlog file  
		---------------------------------------------------------------
		
		

		Begin Try

				Exec SP_BSMasterlogCollectorUncompressFile @CompressMasterlogFileNameFullPath , @CompressionExtension , 
						                             @WorkDirectory,@UnCompressExecutablePath , 
													 @MasterlogFileNameFullPath Output , @ErrorDescription Output

				

				if ( @MasterlogFileNameFullPath is NULL )
				Begin

						set @ErrorDescription = 'SP_BSMasterlogCollectorUncompressFile : '+ convert(varchar(30) ,getdate() , 120) +
												' : ' + ' ERROR !!! ' + @ErrorDescription

						Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

						set @ErrorDescription = 'SP_BSCollectorExportMasterlogFiles : '+ convert(varchar(30) ,getdate() , 120) +
												' : ' + ' ERROR !!! When extracting Masterlog file: '+ @MasterlogFileNameWithoutExtension + ' from the Compress exported file'
				
						Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

						set @ResultFlag = 1

						CLOSE db_cur_get_Masterlog_Files
						DEALLOCATE db_cur_get_Masterlog_Files

						GOTO ENDPROCESS

				End

		End Try

		Begin Catch


						set @ErrorDescription = 'SP_BSCollectorExportMasterlogFiles : '+ convert(varchar(30) ,getdate() , 120) +
												' : ' + ' ERROR !!! Exception during extraction of Masterlog File : ' + @MasterlogFileNameWithoutExtension + '.' + ERROR_MESSAGE()
				
						Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

						set @ResultFlag = 1

						CLOSE db_cur_get_Masterlog_Files
						DEALLOCATE db_cur_get_Masterlog_Files

						GOTO ENDPROCESS

		End Catch
		
		--Select 'Debug: Checking Masterlog file name after completion of uncompress process' as status
		--Select @MasterlogFileNameFullPath as MasterlogFileNameFullPath

		--------------------------------------------------------------
		-- Get the statistics for the Masterlog file post extraction
		--------------------------------------------------------------

		if (@MasterlogExtensionPartOfOriginalFile = 1)
		Begin

		
			Exec SP_BSMasterlogCollectorGetFileDetails  @MasterlogFileName , @MasterlogFileNameFullPath , @FileDetails Output

		End

		else
		Begin 

			Exec SP_BSMasterlogCollectorGetFileDetails  @MasterlogFileNameWithoutExtension , @MasterlogFileNameFullPath , @FileDetails Output

		End	

		set @MasterlogFileSize = substring(@FileDetails,21,len(@FileDetails))

		--Select 'Debug: Checking the size of uncompressed file ' as status
		--Select @MasterlogFileSize as MasterlogFileSize

		---------------------------------------------------------------------------------------
		-- Move the verified Masterlog file to Output directory from where the next module
		-- can pick the file up
		---------------------------------------------------------------------------------------

		------------------------------------------------
		--  STEP 1 : Move the File first as a TEMP File
		------------------------------------------------

		set @cmd = 'Move ' + '"' + @MasterlogFileNameFullPath + '"' + ' ' + '"' + @IntermediateFileNameFullPath + '"'
		
		print @cmd

		Exec master..xp_cmdshell @cmd 

		set @FileExists = 0

		Exec master..xp_fileexist @IntermediateFileNameFullPath , @FileExists output 

		if ( @FileExists <> 1 )
		Begin

 				set @ErrorDescription = 'SP_BSCollectorExportMasterlogFiles : '+ convert(varchar(30) ,getdate() , 120) +
										' : ' + ' ERROR !!! While moving verified Masterlog file: : ' + @MasterlogFileNameWithoutExtension + ' to output folder as TEMP file'
				
				Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

				set @ResultFlag = 1

				CLOSE db_cur_get_Masterlog_Files
				DEALLOCATE db_cur_get_Masterlog_Files

				GOTO ENDPROCESS
				     
		End

		------------------------------------------------
		--  STEP 2 : Rename the TEMP file to actual name
		------------------------------------------------

		set @cmd = 'Rename ' + '"' + @IntermediateFileNameFullPath + '"' + ' ' + @MasterlogFileName
		
		print @cmd

		Exec master..xp_cmdshell @cmd 

		set @FileExists = 0

		set @IntermediateFileNameFullPath = Replace(@IntermediateFileNameFullPath , '.Temp' , @MasterlogFileExtension)

		Exec master..xp_fileexist @IntermediateFileNameFullPath , @FileExists output 

		if ( @FileExists <> 1 )
		Begin

 				set @ErrorDescription = 'SP_BSCollectorExportMasterlogFiles : '+ convert(varchar(30) ,getdate() , 120) +
										' : ' + ' ERROR !!! While renaming verified Temp Masterlog file: : ' + @IntermediateFileNameFullPath + ' in output folder by removing the TEMP Extension'
				
				Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

				set @ResultFlag = 1

				CLOSE db_cur_get_Masterlog_Files
				DEALLOCATE db_cur_get_Masterlog_Files

				GOTO ENDPROCESS
				     
		End
		 

		-----------------------------------------------------------------------------------
		-- insert the statistic in the Collector Staistics table and delete the residual 
		-- Compressed and MD5 files.
		-----------------------------------------------------------------------------------

		insert into TB_MasterlogCollectorStatistics
		(MasterlogFileName , CompressFileSizeInBytes, UnCompressFileSizeInBytes, FileTimeStamp, FileStatus)
        values
		(@MasterlogFileNameWithoutExtension , @CompressedFileSize , @MasterlogFileSize  , @FileTimeStamp , 'File Exported')

		----------------------------------------------
		-- Delete the original compressed Masterlog file
		----------------------------------------------
		---------------------------------------------------------------------------
		-- Commented this code, as we need to hold onto the original raw Masterlog file
		---------------------------------------------------------------------------

		set @cmd = 'Del ' + @CompressMasterlogFileNameFullPath 
		Exec master..xp_cmdshell @cmd 


		set @Random = ROUND(((@Upper - @Lower -1) * RAND() + @Lower), 0)
				set @ProcessLogID = @Random 


				set	@FTPCmdTbName	= 'TmpFTPDelCmd'  +Ltrim(Str(@ProcessLogID))

				set	@FTPCmdFile = @WorkDirectory + @FTPCmdTbName + '.txt'

				--------------------------------------------------------------------
				-- Drop any previous existence of the FTP commnad table and File
				-------------------------------------------------------------------
				
				if exists ( select 1 from sysobjects where name = @FTPCmdTbName and xtype = 'U' )
						   Exec('Drop table '+ @FTPCmdTbName )

				set @FileExists = 0

				Exec master..xp_fileexist @FTPCmdFile , @FileExists output 

				if ( @FileExists = 1 )
				Begin

					set @cmd = 'Del ' + @FTPCmdFile 
					Exec master..xp_cmdshell @cmd 
				     
				End

                -------------------------------------------------------------------------
				-- Build the command(s) to FTP the files into the working Directory
				-------------------------------------------------------------------------

				EXEC	('CREATE	TABLE ' + @FTPCmdTbName + ' (Command	varchar(255) NULL) ')

				SELECT	@CommandLine = 'open ' + @FTPSiteIPAddress
				EXEC	('INSERT ' + @FTPCmdTbName + ' VALUES(' + ''''  + @CommandLine + '''' + ')' )

				SELECT	@CommandLine = 'cd ' + @FTPSiteDirectory 
				EXEC	('INSERT ' + @FTPCmdTbName + ' VALUES(' + ''''  + @CommandLine + '''' + ')' )

				SELECT	@CommandLine = 'lcd ' + @MasterlogFileExportDirectory 
				EXEC	('INSERT ' + @FTPCmdTbName + ' VALUES(' + ''''  + @CommandLine + '''' + ')' )
				
				SELECT	@CommandLine = 'del ' + @CompressMasterlogFileName
				EXEC	('INSERT ' + @FTPCmdTbName + ' VALUES(' + ''''  + @CommandLine + '''' + ')' )
				
				SELECT	@CommandLine = 'bye ' 
				EXEC	('INSERT ' + @FTPCmdTbName + ' VALUES(' + ''''  + @CommandLine + '''' + ')' )

				------------------------------------------------
				-- Create the batch file for running the FTP
				-- commands
				------------------------------------------------

				SELECT 	@cmd = 'bcp '+ db_name() +'.dbo.' + @FTPCmdTbName + ' out ' + 
						@FTPCmdFile + ' -S' + @bcpServer + ' -T -c'

				print @cmd

				EXEC 	master..xp_cmdshell @Cmd

				-------------------------
				-- Run the FTP command
				-------------------------

				-- Added the correct syntax for calling PSFTP

				SELECT 	@cmd = '"'+@FTPExecutablePath +'PSFTP"'+' -v -l '+@FTPSiteUsername+ ' -pw '+ @FTPSitePassword+ ' -b ' + @FTPCmdFile 

				print @Cmd
				EXEC 	master..xp_cmdshell @cmd
				
				if exists ( select 1 from sysobjects where name = @FTPCmdTbName and xtype = 'U' )

					Exec('Drop table '+ @FTPCmdTbName )

					set @FileExists = 0

					Exec master..xp_fileexist @FTPCmdFile , @FileExists output 

					if ( @FileExists = 1 )

					Begin

					set @cmd = 'Del ' + @FTPCmdFile 
					Exec master..xp_cmdshell @cmd 
    
					End

		
PROCESSNEXTFILE:		  
		
		FETCH NEXT FROM db_cur_get_Masterlog_Files
		INTO @CompressMasterlogFileName   		 

END

CLOSE db_cur_get_Masterlog_Files
DEALLOCATE db_cur_get_Masterlog_Files


ENDPROCESS:

Return 0
GO
