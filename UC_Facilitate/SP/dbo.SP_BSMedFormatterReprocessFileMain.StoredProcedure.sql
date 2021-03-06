USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMedFormatterReprocessFileMain]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSMedFormatterReprocessFileMain]
(
	@OutputFolderPath varchar(1000),
	@OutputFileExtension varchar(200),
	@RejectFilePath varchar(1000),
	@DiscardFilePath varchar(1000),
	@AbsoluteLogFilePath varchar(1000),
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

-----------------------------------------------------------------
-- Check if their are any files in REPROCESS status and decide
-- whether we need to reprocess the whole file or just the 
-- error records
-----------------------------------------------------------------

Declare @VarCDRFileID int,
        @VarCDRFileName varchar(500),
        @ReprocessingFlag int = 0 -- 0 No , 1 Reprocess File , 2 Reprocess Exceptions

DECLARE db_Reprocess_CDR_File CURSOR FOR 
select CDRFileID , CDRFileName
from tb_MedFormatterOutput
where FileStatus = 'Reprocess' 

OPEN db_Reprocess_CDR_File   
FETCH NEXT FROM db_Reprocess_CDR_File
INTO @VarCDRFileID, @VarCDRFileName

WHILE @@FETCH_STATUS = 0   
BEGIN 

        ---------------------------------------------------------
		-- Call the procedure to check if the file qualifies for
		-- Complete reprocessing or just the reprocessing of
		-- exception records or perhaps no reprocessing at all
		---------------------------------------------------------

		set @ReprocessingFlag = 0
		set @ResultFlag = 0
		set @ErrorDescription = NULL

		select @VarCDRFileID
		
			
		Begin Try

			Exec SP_BSMedFormatterReprocessLevel  @VarCDRFileID, @OutputFolderPath, 
			                                      @OutputFileExtension, @RejectFilePath ,	
												  @DiscardFilePath, @AbsoluteLogFilePath , 
												  @ReprocessingFlag Output,
			                                      @ErrorDescription Output, @ResultFlag Output

		End Try

		Begin Catch

			set @ErrorDescription = 'SP_BSMedFormatterReprocessFileMain : '+ convert(varchar(30) ,getdate() , 120) +
									' : ERROR !!! While checking Reprocessing Level of CDR File :' + @VarCDRFileName + '. ' + ERROR_MESSAGE()
			Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

			set @ResultFlag = 1

			GOTO ENDPROCESS

		End Catch

		if ( @ResultFlag = 1 )
		Begin

			set @ErrorDescription = 'SP_BSMedFormatterReprocessFileMain : '+ convert(varchar(30) ,getdate() , 120) +
									' : ' + ' ERROR !!! While checking CDR file : ' + @VarCDRFileName + ' for extent to which it can be reporcessed'
			Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

			GOTO PROCESSNEXTFILE

		End	

		------------------------------------------------------------------
		-- Depending on the output REPROCESS FLAG perform the appropriate
		-- Reprocessing
		------------------------------------------------------------------

		if ( @ReprocessingFlag = 0 ) -- Cannot Reprocess the file as all correlated records and exception files have been removed
		Begin

			set @ErrorDescription = 'SP_BSMedFormatterReprocessFileMain : '+ convert(varchar(30) ,getdate() , 120) +
									' : ' + ' INFO !!! Output CDR file : ' + @VarCDRFileName + ' does not qualify for Reprocessing so changing status back to PROCESSED'
			Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath	
			
			update tb_MedFormatterOutput
			set FileStatus = 'Processed'
			where CDRFileID = @VarCDRFileID	
			and FileStatus = 'Reprocess'	

		End

		if ( @ReprocessingFlag = 1 ) -- All the correlated data exists, so file can be completely Reprocessed
		Begin

		    set @ResultFlag = 0
			set @ErrorDescription = NULL

			Begin Try

					EXEC    SP_BSMedFormatterReprocessFile
							@VarCDRFileID,
							@OutputFolderPath,
							@OutputFileExtension,
							@RejectFilePath,
							@DiscardFilePath,
							@AbsoluteLogFilePath,
							@ErrorDescription OUTPUT,
							@ResultFlag OUTPUT

			End Try

			Begin Catch

					set @ErrorDescription = 'SP_BSMedFormatterReprocessFileMain : '+ convert(varchar(30) ,getdate() , 120) +
											' : ERROR !!!! While Reprocessing Output CDR File : '+ @VarCDRFileName + '. '+ ERROR_MESSAGE()
					Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

					set @ResultFlag = 1

					GOTO ENDPROCESS

			End Catch	

		End	
		
		if ( @ReprocessingFlag = 2 ) -- Correlated data has been archived or purged, but Exception records exist
		Begin

		    set @ResultFlag = 0
			set @ErrorDescription = NULL

			Begin Try

					EXEC    SP_BSMedFormatterReprocessFileExceptions
							@VarCDRFileID,
							@OutputFolderPath,
							@OutputFileExtension,
							@RejectFilePath,
							@DiscardFilePath,
							@AbsoluteLogFilePath,
							@ErrorDescription OUTPUT,
							@ResultFlag OUTPUT

			End Try

			Begin Catch

					set @ErrorDescription = 'SP_BSMedFormatterReprocessFileMain : '+ convert(varchar(30) ,getdate() , 120) +
											' : ERROR !!!! While Reprocessing exceptions for Output CDR File : '+ @VarCDRFileName + '. '+ ERROR_MESSAGE()
					Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

					set @ResultFlag = 1

					GOTO ENDPROCESS

			End Catch	

		End				
			     
PROCESSNEXTFILE:

	   FETCH NEXT FROM db_Reprocess_CDR_File
	   INTO @VarCDRFileID, @VarCDRFileName 
 
END   

ENDPROCESS:

CLOSE db_Reprocess_CDR_File  
DEALLOCATE db_Reprocess_CDR_File

GO
