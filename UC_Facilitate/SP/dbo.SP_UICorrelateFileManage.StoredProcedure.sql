USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICorrelateFileManage]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UICorrelateFileManage]
(
	@CDRFileName varchar(200),
	@FileType int, -- 0 ( Main File ) 1 ( Discard File )
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

if not exists ( select 1 from tb_MedCorrelateStatistics where CDRFileName = @CDRFileName )
Begin

		set @ErrorDescription = 'Error !!! CDR file with name : ' + @CDRFileName + ' has not been processed by CORRELATE module'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End

-------------------------------------------------------
-- Only valid values for the file type are 0 and 1
-------------------------------------------------------

if ( @FileType not in (0,1) )
Begin

		set @ErrorDescription = 'Error !!! Value passed for File Type parameter is not correct. Valid values are : 0 ( Main ) , 1 ( Discard )'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End


--------------------------------------------------------------------
-- Check the status of the file and decide whether to fetch from the
-- INPUT folder or REJECT folder
--------------------------------------------------------------------

Declare @FileStatus varchar(200),
        @FolderName varchar(1000),
		@CDRFileExtension varchar(100)
		

select @FileStatus = FileStatus
from tb_MedCorrelateStatistics
where cdrfilename = @CDRFileName

if ( @FileStatus not in (select FileStatus from Tb_AccessScopeFileStatus where AccessScopeID = -2) )
Begin

		set @ErrorDescription = 'Error !!! The status of CDR file is not a valid status for CORRELATE module '
		set @ResultFlag = 1
		GOTO ENDPROCESS	

End

----------------------------------------------------------------------------
-- Depending on the file type, extract from the appropriate folder
----------------------------------------------------------------------------

Select @FolderName = ConfigValue
from tb_Config
where AccessScopeID = -2
and Configname =
      Case
			When @FileType = 0 then 'SourceFilePath'
			When @FileType = 1 then 'DiscardFolderPath'
	  End 


---------------------------------------------------------------------
-- Get the extension CDR file from config depending on file status
---------------------------------------------------------------------

Select @CDRFileExtension = ConfigValue
from tb_Config
where AccessScopeID = -2
and Configname = 
      Case
			When @FileStatus = 'Upload InProgress' then 'IntermediateFileExtension'
			Else 'InputFileExtension'
	  End


-------------------------------------------------------------------
-- Prepare the name of the CDR file based on the above information
-------------------------------------------------------------------

if ( right(@FolderName , 1) != '\' )
Begin

		set @FolderName = @FolderName + '\'

End

set @CompleteCDRFileName = 
	Case
		When @FileType = 1 then @FolderName + @CDRFileName + '.Discard'
		When @FileType = 0 then
				Case
					When @FileStatus = 'Upload Completed' then @FolderName + @CDRFileName + '.Processed'
					When @FileStatus = 'Upload Error' then @FolderName + @CDRFileName + @CDRFileExtension + '.ProcessError'
					When @FileStatus = 'Upload InProgress' then @FolderName + @CDRFileName + @CDRFileExtension
				End
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
