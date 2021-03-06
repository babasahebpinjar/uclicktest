USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMedConverterMain]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSMedConverterMain]
(
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As


Declare @AccessScopeID int ,
        @AbsoluteLogFilePath varchar(1000),
		@SemaphoreFilePath varchar(1000),
		@FileExists int,
		@SQLStr varchar(2000)


set @ErrorDescription = NULL
set @ResultFlag = 0

--------------------------------------------------------
-- Get the Access Scope for the CONVERTER module and 
-- check if all the config parameters defined are valid
-- or not
--------------------------------------------------------

Select @AccessScopeID = AccessScopeID
from tb_AccessScope
where AccessScopeName = 'MedConverter'


if (@AccessScopeID is NULL) 
Begin

	set @ErrorDescription = 'ERROR !!!! Please create an entry for the CONVERTER (MedConverter) module in the Access Scope schema'
	RaisError('%s' , 16,1 , @ErrorDescription)
	set @ResultFlag = 1
	Return 1

End

--------------------------------------------------------
-- Validate the Configuration parameters to ensure that
-- no exceptions exist
--------------------------------------------------------

Exec SP_BSValidateConfig @AccessScopeID , @ErrorDescription Output , @ResultFlag Output

if (@ResultFlag = 1)
Begin

	set @ErrorDescription = 'ERROR !!!! Validating Configuration parameters for CONVERTER  module.' + @ErrorDescription
	RaisError('%s' , 16, 1, @ErrorDescription)
	set @ResultFlag = 1
	Return 1

End

--------------------------------------------------------
-- EXTRACT LOG FILE PATH DEFINED IN CONFIG SCHEMA     --
--------------------------------------------------------

select @AbsoluteLogFilePath = ConfigValue
from tb_Config
where ConfigName = 'LogFilePath'
and AccessScopeID = @AccessScopeID

-------------------------------------------------------------
-- GET ALL THE DATA RELATED PARSING RAW CDR FILES --
-------------------------------------------------------------

Declare @RawFileFolder varchar(1000),
		@CDRFileExtension varchar(1000),
		@OutputFolderPath varchar(1000),
		@CDRKeyFieldsFilePath varchar(1000)



select @RawFileFolder = ConfigValue
from tb_Config
where ConfigName = 'RawFileFolder'
and AccessScopeID = @AccessScopeID

select @CDRFileExtension = ConfigValue
from tb_Config
where ConfigName = 'InputFileExtension'
and AccessScopeID = @AccessScopeID

select @OutputFolderPath = ConfigValue
from tb_Config
where ConfigName = 'ProcessedFileFolder'
and AccessScopeID = @AccessScopeID

select @CDRKeyFieldsFilePath = ConfigValue
from tb_Config
where ConfigName = 'CDRKeyFieldsFilePath'
and AccessScopeID = @AccessScopeID

--------------------------------------------------------------------
-- Check if Semaphore exists, indicating that the process should
-- not run
--------------------------------------------------------------------

select @SemaphoreFilePath = ConfigValue
from tb_Config
where ConfigName = 'SemaphoreFilePath'
and AccessScopeID = @AccessScopeID

set @FileExists = 0
        
Exec master..xp_fileexist @SemaphoreFilePath , @FileExists output 

if ( @FileExists = 1 )
Begin
		     
	set @ErrorDescription = 'SP_BSMedConverterMain : '+ convert(varchar(30) ,getdate() , 120) +
	                        ' : ' + ' INFO !!! Semaphore exists for suspending Collecctor'
    Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

	GOTO ENDPROCESS

End

-------------------------------------------------------------------------------
-- Add code to delete all the file entries from the Converter statistics
-- for which failure is due to mismatch in Actual and calculated records

-- This will ensure that the files are again picked up for conversion
-------------------------------------------------------------------------------

Delete from tb_MedConverterStatistics
where FileStatus = 'Failed'
and remarks like '%Mismatch in the total records as per file header and calculation%'
and TotalRecords <> TotalOutputRecords


------------------------------------------------------------------------
-- Check the input folder for list of all the raw CDR files which need 
-- to be parsed
-------------------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tmpGetListOfCDRFilesToParse') )
		Drop table #tmpGetListOfCDRFilesToParse

Create table #tmpGetListOfCDRFilesToParse (CDRFileName varchar(1000))

if (right(@RawFileFolder , 1) <> '\')
	set @RawFileFolder = @RawFileFolder + '\'


Begin Try

		-- Run the "DIR" command on the input folder to get the list of files

		set @SQLStr = 'Dir /b ' + '"' + @RawFileFolder + '*'+ @CDRFileExtension +'"'

		--print @SQLStr

		Insert	#tmpGetListOfCDRFilesToParse
		EXEC 	master..xp_cmdshell @SQLStr

		-- Delete NULL records and record for "File Not Found"

		Delete from #tmpGetListOfCDRFilesToParse
		where CDRfilename is NULL or CDRFileName = 'File Not Found'

		--Select 'Debug: Check the temporary table after running DIR command' as status
		--select * from #tmpGetListOfCDRFilesToParse

End Try

Begin Catch

	set @ErrorDescription = 'SP_BSMedConverterMain : '+ convert(varchar(30) ,getdate() , 120) +
	                        ' : ' + ' ERROR!!! While getting list of raw CDR files from input folder'
    Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

	GOTO ENDPROCESS

End Catch

-- Delete all the files in the temp table, which have already been
-- processed by the converter 

delete tbl1
from #tmpGetListOfCDRFilesToParse tbl1
inner join tb_MedConverterStatistics tbl2
	on tbl1.CDRFileName = tbl2.CDRFileName + @CDRFileExtension

------------------------------------------------------------------
-- Loop through the list of raw CDR files to parse them one by one
-------------------------------------------------------------------

Declare @VarCDRFileName varchar(500)

DECLARE db_cur_get_Raw_CDR_Files CURSOR FOR
select top 100 CDRFileName from #tmpGetListOfCDRFilesToParse -- Put a hard coded limit of 100 because don't want the Converter to run for long time

OPEN db_cur_get_Raw_CDR_Files
FETCH NEXT FROM db_cur_get_Raw_CDR_Files
INTO @VarCDRFileName 

While @@FETCH_STATUS = 0
BEGIN

	set @VarCDRFileName = @RawFileFolder + @VarCDRFileName
	set @ErrorDescription = NULL
	set @ResultFlag = 0

	--select 'DEBUG:' , @VarCDRFileName , @CDRKeyFieldsFilePath , @OutputFolderPath, @CDRFileExtension, @AbsoluteLogFilePath

	Exec SP_BSConverterParseFile @VarCDRFileName, @CDRKeyFieldsFilePath, @OutputFolderPath,
								@CDRFileExtension, @AbsoluteLogFilePath,
								@ErrorDescription Output , @ResultFlag Output

	if (@ResultFlag = 1)
	Begin

			Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath
			GOTO PROCESSNEXTFILE

	End


PROCESSNEXTFILE:		  
		
		FETCH NEXT FROM db_cur_get_Raw_CDR_Files
		INTO @VarCDRFileName   		 

END

CLOSE db_cur_get_Raw_CDR_Files
DEALLOCATE db_cur_get_Raw_CDR_Files


ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tmpGetListOfCDRFilesToParse') )
		Drop table #tmpGetListOfCDRFilesToParse

Return 0


GO
