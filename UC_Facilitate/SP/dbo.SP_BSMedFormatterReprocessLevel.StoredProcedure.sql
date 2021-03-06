USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMedFormatterReprocessLevel]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSMedFormatterReprocessLevel]
(
	@CDRFileID int,
	@OutputFolderPath varchar(1000),
	@OutputFileExtension varchar(200),
	@RejectFilePath varchar(1000),
	@DiscardFilePath varchar(1000),
	@AbsoluteLogFilePath varchar(1000),
	@ReprocessFlag int Output,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0
set @ReprocessFlag = 0

---------------------------------------------------------------------
-- Get the name of the Output CDR File and check if the status of
-- the file is 'Reprocess'
---------------------------------------------------------------------

Declare @OutputFileNameWithoutExtension varchar(1000),
		@OutputFileName varchar(1000),
		@AbsoluteOutputFileName varchar(1000),
		@AbsoluteRejectFileName varchar(1000),
		@AbsoluteDiscardFileName varchar(1000),
		@AbsoluteIntermediateFileName varchar(1000),
		@TotalRecords int,
		@TotalRejectRecords int,
		@TotalDiscardRecords int

select @OutputFileNameWithoutExtension = CDRFileName,
       @TotalRecords = TotalRecords,
	   @TotalRejectRecords = TotalRejectRecords,
	   @TotalDiscardRecords = TotalDiscardRecords
from tb_MedFormatterOutput
where CDRFileID = @CDRFileID


if ( @OutputFileNameWithoutExtension is NULL )
Begin

		set @ErrorDescription = 'ERROR !!! Output CDR File for which reprocess extent is being checked, does not exist'
  
		set @ErrorDescription = 'SP_BSMedFormatterReprocessLevel : '+ convert(varchar(30) ,getdate() , 120) +
								' : ' + @ErrorDescription
		Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

		set @ResultFlag = 1

		Return 1

End

-----------------------------------------------------------------------
-- Check if the Correlated Unformatted CDRs for the file are still
-- available or not. In case they have been archived then we can only 
-- reprocess the exceptions and not the whole file
------------------------------------------------------------------------

if ( (select count(*) from tb_MedCorrelateMapBER where OutCDRFileID = @CDRFileID) = @TotalRecords )
Begin

		set @ReprocessFlag = 1
		Return 0

End

---------------------------------------------------------------
-- If there are no exception records then file does not qualify
-- for reprocessing
----------------------------------------------------------------

if ( (@TotalDiscardRecords +  @TotalRejectRecords ) = 0 )
Begin

		set @ReprocessFlag = 0
		Return 0

End

-----------------------------------------------------------------
-- By this time we have established that there are Exception CDRs
-- ( Reject or Discard or Both) for this file, so need to ensure
-- that the Exception files exist, as they contain the RAW CDR
-- records
------------------------------------------------------------------

-------------------------------------------------------------------
--  Build the complete names of Output , Discard and Reject Files
-------------------------------------------------------------------


set @OutputFileName = @OutputFileNameWithoutExtension + @OutputFileExtension

set @AbsoluteOutputFileName =
                    Case
					    When right(@OutputFolderPath , '1') <> '\' then @OutputFolderPath + '\' +@OutputFileName
						Else @OutputFolderPath + @OutputFileName
					End 


set @AbsoluteRejectFileName = 
                    Case
					    When right(@RejectFilePath , '1') <> '\' then @RejectFilePath + '\' + @OutputFileNameWithoutExtension + '.Reject'
						Else @RejectFilePath +  @OutputFileNameWithoutExtension + '.Reject'
					End

set @AbsoluteDiscardFileName = 
                    Case
					    When right(@DiscardFilePath , '1') <> '\' then @DiscardFilePath + '\' + @OutputFileNameWithoutExtension + '.Discard'
						Else @DiscardFilePath +  @OutputFileNameWithoutExtension + '.Discard'
					End 


------------------------------------------------------------
-- Check if the REJECT and DISCARD Files Exist or not
------------------------------------------------------------

set @ReprocessFlag = 2

------------
-- DISCARD
------------

Declare @FileExists int

set @FileExists = 0

Exec master..xp_fileexist  @AbsoluteDiscardFileName , @FileExists output 

If ( (@TotalDiscardRecords = 1 ) and (@FileExists = 0))
Begin

		set @ReprocessFlag = 0
		Return 0

End

----------------
-- REJECT
----------------

set @FileExists = 0

Exec master..xp_fileexist  @AbsoluteRejectFileName , @FileExists output 

If ( (@TotalRejectRecords = 1 ) and (@FileExists = 0))
Begin

		set @ReprocessFlag = 0
		Return 0

End


GO
