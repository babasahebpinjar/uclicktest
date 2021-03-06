USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMedFormatterMain]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSMedFormatterMain]
(
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As


Declare @AccessScopeID int ,
        @AbsoluteLogFilePath varchar(1000),
		@OutputFolderPath varchar(1000),
		@CDRFileExtension varchar(1000),
		@RejectFilePath varchar(1000),
		@InputFolderPath varchar(1000),
		@DuplicateFilePath varchar(1000),
		@SemaphoreFilePath varchar(1000),
		@FileExists int,
		@SQLStr varchar(2000)


set @ErrorDescription = NULL
set @ResultFlag = 0

--------------------------------------------------------
-- Get the Access Scope for the Correlate module and 
-- check if all the config parameters defined are valid
-- or not
--------------------------------------------------------

Select @AccessScopeID = AccessScopeID
from tb_AccessScope
where AccessScopeName = 'MedFormatter'


if (@AccessScopeID is NULL) 
Begin

	set @ErrorDescription = 'ERROR !!!! Please create an entry for the FORMATTER (MedFormatter) module in the Access Scope schema'
	RaisError('%s' , @ErrorDescription , 16, 1)
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

	set @ErrorDescription = 'ERROR !!!! Validating Configuration parameters for FORMATTER  module'
	RaisError('%s' , 16,1 , @ErrorDescription)
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
-- GET THE FOLLOWING PARAMETERS                            
-- OutputFolderPath
-- CDRFileExtension
-- RejectFilePath
-- InputFolderPath
-- DuplicateFilePath
-------------------------------------------------------------

select @OutputFolderPath = ConfigValue
from tb_Config
where ConfigName = 'OutputFolderPath'
and AccessScopeID = @AccessScopeID

select @CDRFileExtension = ConfigValue
from tb_Config
where ConfigName = 'CDRFileExtension'
and AccessScopeID = @AccessScopeID

select @RejectFilePath = ConfigValue
from tb_Config
where ConfigName = 'RejectFilePath'
and AccessScopeID = @AccessScopeID

select @InputFolderPath = ConfigValue
from tb_Config
where ConfigName = 'InputFolderPath'
and AccessScopeID = @AccessScopeID

select @DuplicateFilePath = ConfigValue
from tb_Config
where ConfigName = 'DuplicateFilePath'
and AccessScopeID = @AccessScopeID

-------------------------------------------------
-- Get the values for Row and Field delimtier
-- to be for records in the input file
-------------------------------------------------
Declare @RowDelimiter varchar(50),
		@FieldDelimiter varchar(50)


select @RowDelimiter = ConfigValue
from tb_Config
where ConfigName = 'RowDelimiter'
and AccessScopeID = @AccessScopeID

select @FieldDelimiter = ConfigValue
from tb_Config
where ConfigName = 'FieldDelimiter'
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
		     
	set @ErrorDescription = 'SP_BSMedFormatterMain : '+ convert(varchar(30) ,getdate() , 120) +
	                        ' : ' + ' INFO !!! Semaphore exists for suspending Formatter'
    Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

	Return 0

End

------------------------------------------------------------------------------
-- Get all the files form the input folder, pending formatting and output
-- file creation
------------------------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tmpGetListOfCDRFilesToFormat') )
		Drop table #tmpGetListOfCDRFilesToFormat

Create table #tmpGetListOfCDRFilesToFormat (CDRFileName varchar(1000))

if (right(@InputFolderPath , 1) <> '\')
	set @InputFolderPath = @InputFolderPath + '\'


Begin Try

		-- Run the "DIR" command on the input folder to get the list of files

		set @SQLStr = 'Dir /b ' + '"' + @InputFolderPath + '*'+ @CDRFileExtension +'"'

		--print @SQLStr

		Insert	#tmpGetListOfCDRFilesToFormat
		EXEC 	master..xp_cmdshell @SQLStr

		-- Delete NULL records and record for "File Not Found"

		Delete from #tmpGetListOfCDRFilesToFormat
		where CDRfilename is NULL or CDRFileName = 'File Not Found'

		Select 'Debug: Check the temporary table after running DIR command' as status
		select * from #tmpGetListOfCDRFilesToFormat

End Try

Begin Catch

	set @ErrorDescription = 'SP_BSMedFormatterMain : '+ convert(varchar(30) ,getdate() , 120) +
	                        ' : ' + ' ERROR!!! While getting list of CDR files from input folder'
    Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

	GOTO ENDPROCESS

End Catch

-- Delete all the files in the temp table, which have already been
-- processed by the formatter 

delete tbl1
from #tmpGetListOfCDRFilesToFormat tbl1
inner join tb_MedFormatterStatistics tbl2
	on tbl1.CDRFileName = tbl2.CDRFileName + @CDRFileExtension
where tbl2.FileStatus = 'Completed'

------------------------------------------------------------------
-- Loop through the list of  CDR files to format them one by one
-------------------------------------------------------------------

Declare @VarCDRFileName varchar(500)

DECLARE db_cur_get_Format_CDR_Files CURSOR FOR
select top 100 CDRFileName from #tmpGetListOfCDRFilesToFormat -- Put a hard coded limit of 100 because don't want the Formatter to run for long time

OPEN db_cur_get_Format_CDR_Files
FETCH NEXT FROM db_cur_get_Format_CDR_Files
INTO @VarCDRFileName 

While @@FETCH_STATUS = 0
BEGIN

	set @VarCDRFileName = @InputFolderPath + @VarCDRFileName
	set @ErrorDescription = NULL
	set @ResultFlag = 0

	Exec SP_BSMedFormatterCreateFile @VarCDRFileName, @OutputFolderPath,
									 @RejectFilePath, @DuplicateFilePath,
									 @RowDelimiter, @FieldDelimiter,
									 @CDRFileExtension, @AbsoluteLogFilePath,
									 @ErrorDescription , @ResultFlag

	if (@ResultFlag = 1)
	Begin

			Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath
			GOTO PROCESSNEXTFILE

	End


PROCESSNEXTFILE:		  
		
		FETCH NEXT FROM db_cur_get_Format_CDR_Files
		INTO @VarCDRFileName   		 

END

CLOSE db_cur_get_Format_CDR_Files
DEALLOCATE db_cur_get_Format_CDR_Files


ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tmpGetListOfCDRFilesToFormat') )
	Drop table #tmpGetListOfCDRFilesToFormat


Return 0





GO
