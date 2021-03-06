USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIConverterFileManage]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIConverterFileManage]
(
	@CDRFileName varchar(200),
	@CompleteCDRFileName varchar(1000) Output,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription  = NULL
set @ResultFlag = 0
set @CompleteCDRFileName = NULL

--------------------------------------------------
-- Trim any spaces from the name of the CDR File
--------------------------------------------------

set @CDRFileName = rtrim(ltrim(@CDRFileName))

------------------------------------------------------------------
--  Check if this CDR file actually exists for the Converter
------------------------------------------------------------------

if not exists ( select 1 from tb_MedConverterStatistics where CDRFileName = @CDRFileName )
Begin

		set @ErrorDescription = 'Error !!! CDR file with name : ' + @CDRFileName + ' has not been processed by CONVERTER module'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End

--------------------------------------------------------------------
-- Check the status of the file and decide whether to fetch from the
-- PROCESSED folder or REJECT folder
--------------------------------------------------------------------

Declare @FileStatus varchar(200),
        @FolderName varchar(1000),
		@CDRFileExtension varchar(100)

select @FileStatus = FileStatus
from tb_MedConverterStatistics
where cdrfilename = @CDRFileName

if ( @FileStatus not in (select FileStatus from Tb_AccessScopeFileStatus where AccessScopeID = -1) )
Begin

		set @ErrorDescription = 'Error !!! The status of CDR file is not a valid status for CONVERTER module '
		set @ResultFlag = 1
		GOTO ENDPROCESS	

End

----------------------------------------------------------------------------
-- Depending on the status of the file, extract from the appropriate folder
----------------------------------------------------------------------------

if ( @FileStatus = 'Rejected' )
Begin

		Select @FolderName = ConfigValue
		from tb_Config
		where AccessScopeID = -1
		and Configname = 'RejectFilePath'

End

if ( @FileStatus = 'Completed' )
Begin

		Select @FolderName = ConfigValue
		from tb_Config
		where AccessScopeID = -1
		and Configname = 'ProcessedFileFolder'

End

-------------------------------------------------------------
-- Get the original extension of the raw CDR file from config
-------------------------------------------------------------

Select @CDRFileExtension = ConfigValue
from tb_Config
where AccessScopeID = -1
and Configname = 'InputFileExtension'


-------------------------------------------------------------------
-- Prepare the name of the CDR file based on the above information
-------------------------------------------------------------------

if ( right(@FolderName , 1) != '\' )
Begin

		set @FolderName = @FolderName + '\'

End

set @CompleteCDRFileName = 
	Case
		When @FileStatus = 'Completed' then @FolderName + @CDRFileName + @CDRFileExtension + '.Processed'
		When @FileStatus = 'Rejected' then @FolderName + @CDRFileName + @CDRFileExtension
	End


-------------------------------------------------
-- Check if the CDR file exists at the location 
-------------------------------------------------

Declare @FileExists int

set @FileExists = 0

Exec master..xp_fileexist  @CompleteCDRFileName , @FileExists output 

If (@FileExists <> 1)
Begin

		set @ErrorDescription = 'Error !!! The CDR file : ' + @CompleteCDRFileName + ' does not exist'
		set @ResultFlag = 1
		GOTO ENDPROCESS	

End


ENDPROCESS:

Return
GO
