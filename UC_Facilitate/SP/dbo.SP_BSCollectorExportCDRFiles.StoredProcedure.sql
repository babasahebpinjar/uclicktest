USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSCollectorExportCDRFiles]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSCollectorExportCDRFiles]
(
	@FTPSiteIPAddress varchar(1000), 
	@FTPSiteUSerName varchar(1000),
	@FTPSitePassword varchar(1000), 
	@WorkDirectory varchar(1000),
	@FTPSiteDirectory varchar(1000), 
	@FTPExecutablePath varchar(1000), 
	@CompressionExtension varchar(1000) ,
	@CDRExtensionPartOfOriginalFile int,
	@CDRFileExtension varchar(1000),
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
-- Declare variables for building the name of the CDR and check sum files
---------------------------------------------------------------------------

Declare @CompressCDRFileName varchar(500),
        @CDRFileNameWithoutExtension varchar(500),
		@CDRFileName varchar(500),
		@CDRFileNameFullPath varchar(1000),
		@IntermediateFileNameFullPath varchar(1000),
        @CompressCDRFileNameFullPath varchar(1000),
		@CDRFileExportDirectory varchar(1000),
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
		@CDRFileSize varchar(200)

if ( right(@WorkDirectory , 1) = '\')
	set @CDRFileExportDirectory  = left(@WorkDirectory, len(@WorkDirectory) -1 )
else 
	set @CDRFileExportDirectory  = @WorkDirectory

if ( right(@WorkDirectory , 1) <> '\')
	set @WorkDirectory  = @WorkDirectory  + '\'

if ( right(@FTPExecutablePath , 1) <> '\')
	set @FTPExecutablePath  = @FTPExecutablePath  + '\'

if ( right(@OutputFolderPath , 1) <> '\')
	set @OutputFolderPath  = @OutputFolderPath  + '\'

-----------------------------------------------------------------------------
-- Delibrately hard coded to 100 files because dont want the collector process 
-- to run for too long. There have been instances,when the unzip process tends
-- to hang and locks the compress file also
------------------------------------------------------------------------------

DECLARE db_cur_get_CDR_Files CURSOR FOR
select top 100 rowdata from #tmpOutputGetLisOfCDRFiles

OPEN db_cur_get_CDR_Files
FETCH NEXT FROM db_cur_get_CDR_Files
INTO @CompressCDRFileName 

While @@FETCH_STATUS = 0
BEGIN

        Begin Try

				-------------------------------------------------------------
				-- Get a unique Process Log ID for creating temp FTP tables
				-------------------------------------------------------------

				set @Random = ROUND(((@Upper - @Lower -1) * RAND() + @Lower), 0)
				set @ProcessLogID = @Random 

				--------------------------------------------------------------------
				-- Perform all the essential steps to FTP the CDR and Checksum files
				--------------------------------------------------------------------

				Select  @bcpServer=@@ServerName

				if (@CDRExtensionPartOfOriginalFile = 1)
				Begin

					set @CDRFileNameWithoutExtension = substring(@CompressCDRFileName , 1  , len(@CompressCDRFileName) - len(@CompressionExtension) - len(@CDRFileExtension))
					set @CDRFileName = substring(@CompressCDRFileName , 1  , len(@CompressCDRFileName) - len(@CompressionExtension))

				End

				else
				Begin

					set @CDRFileNameWithoutExtension = substring(@CompressCDRFileName , 1  , len(@CompressCDRFileName) - len(@CompressionExtension))
					set @CDRFileName = substring(@CompressCDRFileName , 1  , len(@CompressCDRFileName) - len(@CompressionExtension)) + @CDRFileExtension

				End

				set @IntermediateFileNameFullPath = @OutputFolderPath + @CDRFileNameWithoutExtension + '.Temp'

				set @CompressCDRFileNameFullPath = @WorkDirectory + @CompressCDRFileName

				--Select 'Debug: Publish all the different file names' as status
				--Select @CDRFileNameWithoutExtension as CDRFileNameWithoutExtension,
				--	   @CDRFileName as CDRFileName,
				--	   @IntermediateFileNameFullPath as IntermediateFileNameFullPath,
				--	   @CompressCDRFileNameFullPath as CompressCDRFileNameFullPath


				--------------------------------------------------------------------------------
				-- Delete any previous instance of the Compressed CDR and Check sum file from 
				-- the working directory
				-------------------------------------------------------------------------------

				set @FileExists = 0

				Exec master..xp_fileexist @CompressCDRFileNameFullPath , @FileExists output 

				if ( @FileExists = 1 )
				Begin

					set @cmd = 'Del ' + @CompressCDRFileNameFullPath 
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

				SELECT	@CommandLine = 'lcd ' + @CDRFileExportDirectory 
				EXEC	('INSERT ' + @FTPCmdTbName + ' VALUES(' + ''''  + @CommandLine + '''' + ')' )
				
				SELECT	@CommandLine = 'get ' + @CompressCDRFileName
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

				set @ErrorDescription = 'SP_BSCollectorExportCDRFiles : '+ convert(varchar(30) ,getdate() , 120) +
										' : ' + ' ERROR !!! Performing FTP for CDR file : ' + @CDRFileNameWithoutExtension + ' . ' + ERROR_MESSAGE()
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

				CLOSE db_cur_get_CDR_Files
				DEALLOCATE db_cur_get_CDR_Files

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

		Exec master..xp_fileexist @CompressCDRFileNameFullPath , @FileExists output

		--------------------------------------------------------------------------------
		-- Publish an error message in the log file in case both files are not exported
		--------------------------------------------------------------------------------

        if ( @FileExists <> 1 )
		Begin
		 
				set @ErrorDescription = 'SP_BSCollectorExportCDRFiles : '+ convert(varchar(30) ,getdate() , 120) +
										' : ' + ' ERROR !!! Compressesd CDR file: '+ @CompressCDRFileName + ' has not been exported'
				
				Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

				GOTO PROCESSNEXTFILE

		End

		--------------------------------------------------------------
		-- Get the statistics for the compressed file post export
		--------------------------------------------------------------

		Exec SP_BSMedCollectorGetFileDetails @CompressCDRFileName , @CompressCDRFileNameFullPath , @FileDetails Output

		set @FileTimeStamp = substring(@FileDetails,1,20)
		set @CompressedFileSize = substring(@FileDetails,21,len(@FileDetails))

		--Select 'Debug: Publish File time stamp and size for Compress File' as status
		--select @FileTimeStamp as FileTimeStamp,
		--	   @CompressedFileSize as CompressedFileSize,
		--	   @CompressCDRFileName as CompressCDRFileName

        ---------------------------------------------------------------
		-- Uncompress the CDR file to extract the original CDR file  
		---------------------------------------------------------------

		Begin Try

				Exec SP_BSMedCollectorUncompressFile @CompressCDRFileNameFullPath , @CompressionExtension , 
						                             @WorkDirectory,@UnCompressExecutablePath , 
													 @CDRFileNameFullPath Output , @ErrorDescription Output

				

				if ( @CDRFileNameFullPath is NULL )
				Begin

						set @ErrorDescription = 'SP_BSMedCollectorUncompressFile : '+ convert(varchar(30) ,getdate() , 120) +
												' : ' + ' ERROR !!! ' + @ErrorDescription

						Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

						set @ErrorDescription = 'SP_BSCollectorExportCDRFiles : '+ convert(varchar(30) ,getdate() , 120) +
												' : ' + ' ERROR !!! When extracting CDR file: '+ @CDRFileNameWithoutExtension + ' from the Compress exported file'
				
						Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

						set @ResultFlag = 1

						CLOSE db_cur_get_CDR_Files
						DEALLOCATE db_cur_get_CDR_Files

						GOTO ENDPROCESS

				End

		End Try

		Begin Catch


						set @ErrorDescription = 'SP_BSCollectorExportCDRFiles : '+ convert(varchar(30) ,getdate() , 120) +
												' : ' + ' ERROR !!! Exception during extraction of CDR File : ' + @CDRFileNameWithoutExtension + '.' + ERROR_MESSAGE()
				
						Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

						set @ResultFlag = 1

						CLOSE db_cur_get_CDR_Files
						DEALLOCATE db_cur_get_CDR_Files

						GOTO ENDPROCESS

		End Catch

		--Select 'Debug: Checking CDR file name after completion of uncompress process' as status
		--Select @CDRFileNameFullPath as CDRFileNameFullPath

		--------------------------------------------------------------
		-- Get the statistics for the CDR file post extraction
		--------------------------------------------------------------

		if (@CDRExtensionPartOfOriginalFile = 1)
		Begin

		
			Exec SP_BSMedCollectorGetFileDetails  @CDRFileName , @CDRFileNameFullPath , @FileDetails Output

		End

		else
		Begin 

			Exec SP_BSMedCollectorGetFileDetails  @CDRFileNameWithoutExtension , @CDRFileNameFullPath , @FileDetails Output

		End	

		set @CDRFileSize = substring(@FileDetails,21,len(@FileDetails))

		--Select 'Debug: Checking the size of uncompressed file ' as status
		--Select @CDRFileSize as CDRFileSize

		---------------------------------------------------------------------------------------
		-- Move the verified CDR file to Output directory from where the next module
		-- can pick the file up
		---------------------------------------------------------------------------------------

		------------------------------------------------
		--  STEP 1 : Move the File first as a TEMP File
		------------------------------------------------

		set @cmd = 'Move ' + '"' + @CDRFileNameFullPath + '"' + ' ' + '"' + @IntermediateFileNameFullPath + '"'
		
		print @cmd

		Exec master..xp_cmdshell @cmd 

		set @FileExists = 0

		Exec master..xp_fileexist @IntermediateFileNameFullPath , @FileExists output 

		if ( @FileExists <> 1 )
		Begin

 				set @ErrorDescription = 'SP_BSCollectorExportCDRFiles : '+ convert(varchar(30) ,getdate() , 120) +
										' : ' + ' ERROR !!! While moving verified CDR file: : ' + @CDRFileNameWithoutExtension + ' to output folder as TEMP file'
				
				Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

				set @ResultFlag = 1

				CLOSE db_cur_get_CDR_Files
				DEALLOCATE db_cur_get_CDR_Files

				GOTO ENDPROCESS
				     
		End

		------------------------------------------------
		--  STEP 2 : Rename the TEMP file to actual name
		------------------------------------------------

		set @cmd = 'Rename ' + '"' + @IntermediateFileNameFullPath + '"' + ' ' + @CDRFileName
		
		print @cmd

		Exec master..xp_cmdshell @cmd 

		set @FileExists = 0

		set @IntermediateFileNameFullPath = Replace(@IntermediateFileNameFullPath , '.Temp' , @CDRFileExtension)

		Exec master..xp_fileexist @IntermediateFileNameFullPath , @FileExists output 

		if ( @FileExists <> 1 )
		Begin

 				set @ErrorDescription = 'SP_BSCollectorExportCDRFiles : '+ convert(varchar(30) ,getdate() , 120) +
										' : ' + ' ERROR !!! While renaming verified Temp CDR file: : ' + @IntermediateFileNameFullPath + ' in output folder by removing the TEMP Extension'
				
				Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

				set @ResultFlag = 1

				CLOSE db_cur_get_CDR_Files
				DEALLOCATE db_cur_get_CDR_Files

				GOTO ENDPROCESS
				     
		End
		 

		-----------------------------------------------------------------------------------
		-- insert the statistic in the Collector Staistics table and delete the residual 
		-- Compressed and MD5 files.
		-----------------------------------------------------------------------------------

		insert into tb_MedCollectorStatistics
		(CDRFileName , CompressFileSizeInBytes, UnCompressFileSizeInBytes, FileTimeStamp, FileStatus)
        values
		(@CDRFileNameWithoutExtension , @CompressedFileSize , @CDRFileSize  , @FileTimeStamp , 'File Exported')

		----------------------------------------------
		-- Delete the original compressed CDR file
		----------------------------------------------
		---------------------------------------------------------------------------
		-- Commented this code, as we need to hold onto the original raw CDR file
		---------------------------------------------------------------------------

		--set @cmd = 'Del ' + @CompressCDRFileNameFullPath 
		--Exec master..xp_cmdshell @cmd 

		
PROCESSNEXTFILE:		  
		
		FETCH NEXT FROM db_cur_get_CDR_Files
		INTO @CompressCDRFileName   		 

END

CLOSE db_cur_get_CDR_Files
DEALLOCATE db_cur_get_CDR_Files


ENDPROCESS:

Return 0
GO
