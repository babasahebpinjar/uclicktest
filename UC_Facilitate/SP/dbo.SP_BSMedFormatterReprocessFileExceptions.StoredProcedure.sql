USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMedFormatterReprocessFileExceptions]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSMedFormatterReprocessFileExceptions]
(
	@CDRFileID int,
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
		@TotalOldRejectRecords int,
		@TotalOldDiscardRecords int,
        @TotalOldOutputRecordCount int,
        @TotalOldProcessedRecords int,
		@TotalOldProcessedMinutes Decimal(19,2),
		@TotalOldDiscardMinutes Decimal(19,2),
		@TotalOldRejectMinutes Decimal(19,2),
		@TotalOldMinutes Decimal(19,2),
		-------------------------------------------------------
		-- Need these flags to control the rollback process
		-- in case of an exception
		-------------------------------------------------------
		@StatisticsUpdateFlag int = 0,
		@StatisticsDetailUpdateFlag int = 0,
		@ReprocessOutputFileCreateFlag int = 0,
		@ReprocessRejectFileCreateFlag int = 0,
		@ReprocessDiscardFileCreateFlag int = 0



select @OutputFileNameWithoutExtension = CDRFileName,
       @TotalRecords = TotalRecords ,
	   @TotalOldRejectRecords = TotalRejectRecords,
	   @TotalOldDiscardRecords = TotalDiscardRecords,
	   @TotalOldProcessedRecords = TotalProcessedRecords,
	   @TotalOldMinutes = TotalMinutes,
	   @TotalOldProcessedMinutes = TotalProcessedMinutes,
	   @TotalOldDiscardMinutes = TotalDiscardMinutes,
	   @TotalOldRejectMinutes = TotalRejectMinutes
from tb_MedFormatterOutput
where CDRFileID = @CDRFileID
and FileStatus = 'Reprocess'


if ( @OutputFileNameWithoutExtension is NULL )
Begin

		set @ErrorDescription = 'ERROR !!! Output CDR File cannot be Reprocessed, as it does not exist or status is not set to "REPROCESS"'
  
		set @ErrorDescription = 'SP_BSMedFormatterReprocessFileExceptions : '+ convert(varchar(30) ,getdate() , 120) +
								' : ' + @ErrorDescription
		Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

		set @ResultFlag = 1

		GOTO ENDPROCESS

End

--------------------------------------------------------------
-- Store the old values for REJECT and DISCARD details incase
-- needed for Rollback during exception
---------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_MedFormatterDiscardDetails') )
		Drop table #temp_MedFormatterDiscardDetails

select *
into #temp_MedFormatterDiscardDetails
from tb_MedFormatterOutputDiscardDetails
where CDRFileID = @CDRFileID

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_MedFormatterRejectDetails') )
		Drop table #temp_MedFormatterRejectDetails

select *
into #temp_MedFormatterRejectDetails
from tb_MedFormatterOutputRejectDetails
where CDRFileID = @CDRFileID


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


---------------------------------------------------------------
-- Look at the Output table definition and use it to load the
-- Output CDR file into the database
---------------------------------------------------------------

Declare @FileExists int,
        @Command varchar(3000),
		@FileDefinitionID int,
		@OutputFileDefinitionID int,
		@SQLStr nvarchar(max)

select @FileDefinitionID = convert(int , tbl1.ConfigValue)
from tb_Config tbl1
inner join tb_AccessScope tbl2 on tbl1.AccessScopeID = tbl2.AccessScopeID
where tbl2.AccessScopeName = 'MedFormatter'
and tbl1.Configname = 'IntermediateFormatterFileDefinition'

if ( @FileDefinitionID is NULL )
Begin

		set @ErrorDescription = 'ERROR !!! Configuration missing for the InterMediate CDR File Definition (OutFormatterFileDefinition)'
  
		set @ErrorDescription = 'SP_BSMedFormatterReprocessFileExceptions : '+ convert(varchar(30) ,getdate() , 120) +
								' : ' + @ErrorDescription
		Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

		set @ResultFlag = 1

		GOTO ENDPROCESS

End

set @ResultFlag = 0
set @ErrorDescription = NULL

if exists (select 1 from sysobjects where xtype = 'U' and name = @OutputFileNameWithoutExtension )
	Exec('Drop table ' + @OutputFileNameWithoutExtension )

--Select 'Debug :  Before Creating the Temp Table for Reject and Discard Records'

Exec SP_BSMedFormatterDynamicTableCreate    @FileDefinitionID , @OutputFileNameWithoutExtension,
			                                @AbsoluteLogFilePath , @ErrorDescription Output,
											@ResultFlag Output

if ( @ResultFlag = 1 ) 
Begin

		set @ErrorDescription = 'ERROR !!! During creation of table for storing exception records during reprocessing'
  
		set @ErrorDescription = 'SP_BSMedFormatterReprocessFileExceptions : '+ convert(varchar(30) ,getdate() , 120) +
								' : ' + @ErrorDescription
		Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

		set @ResultFlag = 1

		GOTO ENDPROCESS 

End

--Select 'Debug :  After Creating the Temp Table for Reject and Discard Records'

--if exists (select 1 from sysobjects where xtype = 'U' and name = @OutputFileNameWithoutExtension )
--		Select 'Debug : Table Created Successfully'

---------------------------------------------------------------------------
-- Alter the table and add fields for storing the Error Description Field
---------------------------------------------------------------------------

Exec ('Select * from ' + @OutputFileNameWithoutExtension)

Exec('Alter table ' + @OutputFileNameWithoutExtension + ' Add ErrorDescription varchar(1000)' )


---------------------------------------------------------
-- Bulk upload the rejection file into the temporary table
----------------------------------------------------------

Declare @RowTerminator varchar(100),
		@FieldTerminator varchar(100),
		@result int

if ( @TotalOldRejectRecords <> 0 )
Begin

		Begin Try

			set @RowTerminator = '\n'
			set @FieldTerminator = ',' 

			Select	@SQLStr = 'Bulk Insert ' + @OutputFileNameWithoutExtension + ' From ' 
							  + '''' + @AbsoluteRejectFileName +'''' + ' WITH (
							  FIELDTERMINATOR  = ''' + @FieldTerminator + ''','+
							  'ROWTERMINATOR    = ''' + @RowTerminator + ''''+')'

			print @SQLStr
			Exec (@SQLStr)

		End Try
		Begin Catch

			set @ErrorDescription = 'ERROR: Importing Rejected CDR records for File :' + @OutputFileNameWithoutExtension + ' into Database for Reprocessing.' + ERROR_MESSAGE()
  
			set @ErrorDescription = 'SP_BSMedFormatterReprocessFileExceptions : '+ convert(varchar(30) ,getdate() , 120) +
									' : ' + @ErrorDescription
			Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

			set @ResultFlag = 1

			GOTO ENDPROCESS

		 End Catch

 End

 ---------------------------------------------------------------------------------------
 -- Import the Discarded CDR Records As well from the DISCARD file, before running the
 -- Reprocessing
 ---------------------------------------------------------------------------------------

 if ( @TotalOldDiscardRecords <> 0 )
 Begin

		 Begin Try

			set @RowTerminator = '\n'
			set @FieldTerminator = ',' 

			Select	@SQLStr = 'Bulk Insert ' + @OutputFileNameWithoutExtension + ' From ' 
							  + '''' + @AbsoluteDiscardFileName +'''' + ' WITH (
							  FIELDTERMINATOR  = ''' + @FieldTerminator + ''','+
							  'ROWTERMINATOR    = ''' + @RowTerminator + ''''+')'

			--print @SQLStr
			Exec (@SQLStr)

		End Try
		Begin Catch

			set @ErrorDescription = 'ERROR: Importing Discarded CDR records for File :' + @OutputFileNameWithoutExtension + ' into Database for Reprocessing.' + ERROR_MESSAGE()
  
			set @ErrorDescription = 'SP_BSMedFormatterReprocessFileExceptions : '+ convert(varchar(30) ,getdate() , 120) +
									' : ' + @ErrorDescription
			Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

			set @ResultFlag = 1

			GOTO ENDPROCESS

		 End Catch

 End

--------------------------------------------------------------
-- Move the contents into the temporary table for further
-- processing
---------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..##temp_MedFormatterRecords') )
		Drop table ##temp_MedFormatterRecords

Exec('Select * into ##temp_MedFormatterRecords from ' + @OutputFileNameWithoutExtension)
Exec('Drop table ' + @OutputFileNameWithoutExtension )

---------------------------------------------------------------
-- Post import of Discard and Reject file records, check to
-- ensure that the total records imported are correct
---------------------------------------------------------------

if ( (select count(*) from ##temp_MedFormatterRecords) <> (@TotalOldDiscardRecords + @TotalOldRejectRecords) )
Begin

    set @ErrorDescription = 'ERROR !!! All Discared and Rejected records have not been imported for file : ' + @OutputFileNameWithoutExtension + ' during reprocessing'
  
    set @ErrorDescription = 'SP_BSMedFormatterReprocessFileExceptions : '+ convert(varchar(30) ,getdate() , 120) +
	                        ' : ' + @ErrorDescription
    Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

	set @ResultFlag = 1

	GOTO ENDPROCESS

End

--------------------------------------------------------
-- Drop Error Description field and again Add it in the
-- table so that it is after ERRORTYPE field in the
-- sequence

-- THIS IS DONE TO HANDLE EXCEPTION WHEN STORING PROCESSED
-- DATA INTO TEMP_ALLPROCESSEDRECORDS
--------------------------------------------------------

Alter table ##temp_MedFormatterRecords Drop Column ErrorDescription

------------------------------------------------------------------------
-- Alter the temporary Record Table to hold the Error Type field
------------------------------------------------------------------------

Alter table ##temp_MedFormatterRecords Add ErrorType int Default 0
Alter table ##temp_MedFormatterRecords Add ErrorDescription Varchar(1000)


------------------------------------------------
-- Call the procedure to perform the validation
-- on the CDR records
-------------------------------------------------

Begin Try

		Exec SP_BSMedFormatterCustomValidation 1 ,@AbsoluteLogFilePath,
											   @ErrorDescription Output,
											   @ResultFlag Output

		if (@ResultFlag = 1)
		Begin

			set @ErrorDescription = 'ERROR !!! During Custom Validation process for file : ' + @OutputFileNameWithoutExtension + ' during reprocessing'
  
			set @ErrorDescription = 'SP_BSMedFormatterReprocessFileExceptions : '+ convert(varchar(30) ,getdate() , 120) +
									' : ' + @ErrorDescription
			Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

			set @ResultFlag = 1

			GOTO ENDPROCESS

		End 

End Try


Begin Catch

    set @ErrorDescription = 'ERROR !!! During Custom Validation process for file : ' + @OutputFileNameWithoutExtension + ' during reprocessing.' + ERROR_MESSAGE()
  
    set @ErrorDescription = 'SP_BSMedFormatterReprocessFileExceptions : '+ convert(varchar(30) ,getdate() , 120) +
	                        ' : ' + @ErrorDescription
    Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

	set @ResultFlag = 1

	GOTO ENDPROCESS


End Catch

-------------------------------------------------------------------------------------------
-- Create the temp table to hold the final CDR records in the required output format
-------------------------------------------------------------------------------------------

select @OutputFileDefinitionID = convert(int , tbl1.ConfigValue)
from tb_Config tbl1
inner join tb_AccessScope tbl2 on tbl1.AccessScopeID = tbl2.AccessScopeID
where tbl2.AccessScopeName = 'MedFormatter'
and tbl1.Configname = 'OutFormatterFileDefinition'

if ( @OutputFileDefinitionID is NULL )
Begin

		set @ErrorDescription = 'ERROR !!! Configuration missing for the Output CDR File Definition (OutFormatterFileDefinition)'
  
		set @ErrorDescription = 'SP_BSMedFormatterReprocessFileExceptions : '+ convert(varchar(30) ,getdate() , 120) +
								' : ' + @ErrorDescription
		Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

		set @ResultFlag = 1

		GOTO ENDPROCESS 

End

set @ResultFlag = 0
set @ErrorDescription = NULL

if exists (select 1 from sysobjects where xtype = 'U' and name = @OutputFileNameWithoutExtension )
	Exec('Drop table ' + @OutputFileNameWithoutExtension )

Exec SP_BSMedFormatterDynamicTableCreate    @OutputFileDefinitionID , @OutputFileNameWithoutExtension,
			                                @AbsoluteLogFilePath , @ErrorDescription Output,
											@ResultFlag Output

if ( @ResultFlag = 1 ) 
Begin

		set @ErrorDescription = 'ERROR !!! During creation of table for storing final Output formatter records for reprocessing exceptions of file :' + @OutputFileNameWithoutExtension
  
		set @ErrorDescription = 'SP_BSMedFormatterReprocessFileExceptions : '+ convert(varchar(30) ,getdate() , 120) +
								' : ' + @ErrorDescription
		Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

		set @ResultFlag = 1

		GOTO ENDPROCESS 

End

----------------------------------------------------------------
-- Load the contents from the dynamic table into the temporary
-- table for further processing
----------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..##temp_MedOutputFormatterRecords') )
		Drop table ##temp_MedOutputFormatterRecords

Exec('Select * into ##temp_MedOutputFormatterRecords from ' + @OutputFileNameWithoutExtension)
Exec('Drop table ' + @OutputFileNameWithoutExtension )

------------------------------------------------------------------
-- Alter the Output table to add the Enrichment Flag for tracking
------------------------------------------------------------------

Alter table ##temp_MedOutputFormatterRecords Add EnrichmentFlag int

------------------------------------------------------------------
-- Call the custom procedure to build the output CDR record File
------------------------------------------------------------------

set @ResultFlag = 0
set @ErrorDescription = NULL

Exec SP_BSMedFormatterCustomOutputEnrichment @AbsoluteLogFilePath , 
                                             @ErrorDescription Output,
											 @ResultFlag Output

if ( @ResultFlag = 1 ) 
Begin

		set @ErrorDescription = 'ERROR !!! During enrichment of CDR records to build the Output records for reprocessing of file : '+ @OutputFileNameWithoutExtension
  
		set @ErrorDescription = 'SP_BSMedFormatterReprocessFileExceptions : '+ convert(varchar(30) ,getdate() , 120) +
								' : ' + @ErrorDescription
		Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

		set @ResultFlag = 1

		GOTO ENDPROCESS 

End

----------------------------------------------------------
-- Remove the Enrichment flag from the output table
----------------------------------------------------------

Alter table ##temp_MedOutputFormatterRecords Drop column EnrichmentFlag

-----------------------------------------------------------
-- Calculate all the essential statistics for processing
-- CDR file
-----------------------------------------------------------

Declare @TotalOutputRecordCount int,
        @TotalProcessedRecords int,
		@TotalDiscardRecords int,
		@TotalRejectRecords int,
		@TotalProcessedMinutes Decimal(19,2),
		@TotalDiscardMinutes Decimal(19,2),
		@TotalRejectMinutes Decimal(19,2),
		@TotalMinutes Decimal(19,2)


select @TotalOutputRecordCount = TotalRecords,
       @TotalProcessedRecords = TotalProcessedRecords
from tb_MedFormatterOutput
where CDRFileID = @CDRFileID

select @TotalRejectRecords = count(*)
from ##temp_MedFormatterRecords
where Errortype > 0
and ErrorDescription is Not NULL

select @TotalDiscardRecords = count(*)
from ##temp_MedFormatterRecords
where Errortype < 0
and ErrorDescription is Not NULL

set @TotalProcessedRecords = @TotalProcessedRecords + ((@TotalOldDiscardRecords +  @TotalOldRejectRecords) - (@TotalDiscardRecords + @TotalRejectRecords))

select @TotalMinutes = TotalMinutes,
       @TotalProcessedMinutes = TotalProcessedMinutes
from tb_MedFormatterOutput
where CDRFileID = @CDRFileID


select @TotalRejectMinutes = sum(convert(int ,round(convert(int ,ChargeDuration)/1000.0,0)))/60.0
from ##temp_MedFormatterRecords
where Errortype > 0
and ErrorDescription is Not NULL

select @TotalDiscardMinutes = sum(convert(int ,round(convert(int ,ChargeDuration)/1000.0,0)))/60.0
from ##temp_MedFormatterRecords
where Errortype < 0
and ErrorDescription is Not NULL

select @TotalProcessedMinutes = @TotalProcessedMinutes + isnull(sum(convert(int ,round(convert(int ,ChargeDuration)/1000.0,0)))/60.0,0)
from ##temp_MedFormatterRecords
where ErrorDescription is NULL 

--------------------------------------------------------------------------
-- In order to create the new Statistics and create output files we need
-- to import the records for the successfully processed file
--------------------------------------------------------------------------

Begin Try

		set @RowTerminator = '\n'
		set @FieldTerminator = ',' 

		Select	@SQLStr = 'Bulk Insert ##temp_MedOutputFormatterRecords From ' 
							+ '''' + @AbsoluteOutputFileName +'''' + ' WITH (
							FIELDTERMINATOR  = ''' + @FieldTerminator + ''','+
							'ROWTERMINATOR    = ''' + @RowTerminator + ''''+')'

		--print @SQLStr
		Exec (@SQLStr)

End Try
Begin Catch

		set @ErrorDescription = 'ERROR: Importing Already Successfully processed CDR records for File :' + @OutputFileNameWithoutExtension + ' into Database during Reprocessing.' + ERROR_MESSAGE()
  
		set @ErrorDescription = 'SP_BSMedFormatterReprocessFileExceptions : '+ convert(varchar(30) ,getdate() , 120) +
								' : ' + @ErrorDescription
		Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

		set @ResultFlag = 1

		GOTO ENDPROCESS

End Catch

----------------------------------------------------------------
-- Build the logic to ouptut the contents of the temporary table
-- to a Output File , Reject File and Discard File
----------------------------------------------------------------

Declare @QualifiedTableName varchar(500),
		@bcpCommand varchar(2000),
		@AbsoluteOldOutputFileName varchar(1000),
		@AbsoluteOldRejectFileName varchar(1000),
		@AbsoluteOldDiscardFileName varchar(1000)

---------------------------------------------------------------------
-- Remove any OLD instances of the Output , Reject and Discard File
---------------------------------------------------------------------

----------------------
-- OLD OUTPUT FILE
----------------------

set @AbsoluteOldOutputFileName = @AbsoluteOutputFileName + '.OLD'

set @FileExists = 0

Exec master..xp_fileexist  @AbsoluteOldOutputFileName , @FileExists output 

If (@FileExists = 1)
Begin

			        
		set @Command = 'del ' + '"'+@AbsoluteOldOutputFileName +'"'
		--print @Command 

		Exec master..xp_cmdshell @Command

End

----------------------
-- OLD REJECT FILE
----------------------

set @AbsoluteOldRejectFileName = @AbsoluteRejectFileName + '.OLD'

set @FileExists = 0

Exec master..xp_fileexist  @AbsoluteOldRejectFileName , @FileExists output 

If (@FileExists = 1)
Begin

			        
		set @Command = 'del ' + '"'+@AbsoluteOldRejectFileName +'"'
		--print @Command 

		Exec master..xp_cmdshell @Command

End

------------------------
-- OLD DISCARD FILE
------------------------

set @AbsoluteOldDiscardFileName = @AbsoluteDiscardFileName + '.OLD'

set @FileExists = 0

Exec master..xp_fileexist  @AbsoluteOldDiscardFileName , @FileExists output 

If (@FileExists = 1)
Begin

			        
		set @Command = 'del ' + '"'+@AbsoluteOldDiscardFileName +'"'
		--print @Command 

		Exec master..xp_cmdshell @Command

End


Begin Try

			--------------------------------------------------------------------
			-- **************** START CREATE OUTPUT RECORD FILE ***************
			--------------------------------------------------------------------

			--------------------------------------------------------------
			-- Rename any previous instance of the OUTPUT file if exists
			--------------------------------------------------------------

			set @FileExists = 0

			Exec master..xp_fileexist  @AbsoluteOutputFileName , @FileExists output 

			If (@FileExists = 1)
			Begin

			        
					set @Command = 'ren ' + '"'+@AbsoluteOutputFileName +'"' + ' ' + @OutputFileName + '.OLD'
					--print @Command 

					Exec master..xp_cmdshell @Command

			End

			if exists (select 1 from sysobjects where xtype = 'U' and name = @OutputFileNameWithoutExtension )
				Exec('Drop table ' + @OutputFileNameWithoutExtension )

			Exec ('Select * into ' + @OutputFileNameWithoutExtension + ' from ##temp_MedOutputFormatterRecords')

			set @QualifiedTableName = db_name() + '.dbo.' + @OutputFileNameWithoutExtension

			SET @bcpCommand = 'bcp "SELECT *  from ' +
								@QualifiedTableName +'" queryout ' + '"'+ltrim(rtrim(@AbsoluteOutputFileName)) + '"' +' -c -t "," -r"\n" -T -S '+ @@servername

			exec master..xp_cmdshell @bcpCommand

			----------------------------------------------------
			-- Check if the output file has been created or not 
			----------------------------------------------------

			set @FileExists = 0

			Exec master..xp_fileexist  @AbsoluteOutputFileName , @FileExists output  

			if ( @FileExists <> 1 )
			Begin

				set @ErrorDescription = ' ERROR !!! Failed to Create the Output file : ' + @OutputFileNameWithoutExtension + ' for CDR Records'

				set @ErrorDescription = 'SP_BSMedFormatterReprocessFileExceptions : '+ convert(varchar(30) ,getdate() , 120) +
											' : ' + @ErrorDescription

				Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath


				set @ResultFlag = 1

				GOTO ENDPROCESS

			End

			set @ReprocessOutputFileCreateFlag = 1 -- Need this flag to decide what needs to be rollback in case of exception

			--------------------------------------------------------------------
			-- **************** END CREATE OUTPUT RECORD FILE ***************
			--------------------------------------------------------------------

			--------------------------------------------------------------------
			-- **************** START CREATE REJECT RECORD FILE ***************
			--------------------------------------------------------------------

			--------------------------------------------------------------
			-- Rename any previous instance of the Reject file if exists
			--------------------------------------------------------------

			set @FileExists = 0

			Exec master..xp_fileexist  @AbsoluteRejectFileName , @FileExists output 

			If (@FileExists = 1)
			Begin

					set @Command = 'ren ' + '"'+@AbsoluteRejectFileName +'"' + ' ' + @OutputFileNameWithoutExtension + '.Reject' + '.OLD'
					--print @Command 

					Exec master..xp_cmdshell @Command

			End

			--------------------------------------------------------------------
			-- Only create the REJECT file if there are any rejected records
			---------------------------------------------------------------------

			if exists (select 1 from ##temp_MedFormatterRecords where isnull(Errortype,0) > 0)
			Begin

					if exists (select 1 from sysobjects where xtype = 'U' and name = @OutputFileNameWithoutExtension )
						Exec('Drop table ' + @OutputFileNameWithoutExtension )

					Exec ('Select * into ' + @OutputFileNameWithoutExtension + ' from ##temp_MedFormatterRecords where isnull(Errortype,0) > 0')
					Exec ('Alter table ' + @OutputFileNameWithoutExtension +  ' Drop column ErrorType')

					--Exec ('Select * from ' + @OutputFileNameWithoutExtension)

					set @QualifiedTableName = db_name() + '.dbo.' + @OutputFileNameWithoutExtension

					SET @bcpCommand = 'bcp "SELECT *  from ' +
										@QualifiedTableName +'" queryout ' + '"'+ltrim(rtrim(@AbsoluteRejectFileName)) + '"' +' -c -t "," -r"\n" -T -S '+ @@servername

					exec master..xp_cmdshell @bcpCommand

					----------------------------------------------------
					-- Check if the Reject file has been created or not 
					----------------------------------------------------

					set @FileExists = 0

					Exec master..xp_fileexist  @AbsoluteRejectFileName , @FileExists output  

					if ( @FileExists <> 1 )
					Begin

						set @ErrorDescription = ' ERROR !!! Failed to Create the Reject file : ' + @OutputFileNameWithoutExtension + ' for CDR Records'

						set @ErrorDescription = 'SP_BSMedFormatterReprocessFileExceptions : '+ convert(varchar(30) ,getdate() , 120) +
													' : ' + @ErrorDescription

						Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath


						set @ResultFlag = 1

						GOTO ENDPROCESS

					End

			End

			set @ReprocessRejectFileCreateFlag = 1 -- Need this flag to decide what needs to be rollback in case of exception

			--------------------------------------------------------------------
			-- **************** END CREATE REJECT RECORD FILE ***************
			--------------------------------------------------------------------

			--------------------------------------------------------------------
			-- **************** START CREATE DISCARD RECORD FILE ***************
			--------------------------------------------------------------------

			--------------------------------------------------------------
			-- Remove any previous instance of the DISCARD file if exists
			--------------------------------------------------------------

			set @FileExists = 0

			Exec master..xp_fileexist  @AbsoluteDiscardFileName , @FileExists output 

			If (@FileExists = 1)
			Begin

					set @Command = 'ren ' + '"'+ @AbsoluteDiscardFileName +'"' + ' ' + @OutputFileNameWithoutExtension + '.Discard' + '.OLD'
					--print @Command 

					Exec master..xp_cmdshell @Command

			End

			--------------------------------------------------------------------
			-- Only create the DISCARD file if there are any discarded records
			---------------------------------------------------------------------

			if exists (select 1 from ##temp_MedFormatterRecords where isnull(Errortype,0) < 0)
			Begin

					if exists (select 1 from sysobjects where xtype = 'U' and name = @OutputFileNameWithoutExtension )
						Exec('Drop table ' + @OutputFileNameWithoutExtension )

					Exec ('Select * into ' + @OutputFileNameWithoutExtension + ' from ##temp_MedFormatterRecords where isnull(Errortype,0) < 0')
					Exec ('Alter table ' + @OutputFileNameWithoutExtension +  ' Drop column ErrorType')

					set @QualifiedTableName = db_name() + '.dbo.' + @OutputFileNameWithoutExtension

					SET @bcpCommand = 'bcp "SELECT *  from ' +
										@QualifiedTableName +'" queryout ' + '"'+ltrim(rtrim(@AbsoluteDiscardFileName)) + '"' +' -c -t "," -r"\n" -T -S '+ @@servername

					exec master..xp_cmdshell @bcpCommand

					----------------------------------------------------
					-- Check if the Discard file has been created or not 
					----------------------------------------------------

					set @FileExists = 0

					Exec master..xp_fileexist  @AbsoluteDiscardFileName , @FileExists output  

					if ( @FileExists <> 1 )
					Begin

						set @ErrorDescription = ' ERROR !!! Failed to Create the Discard file : ' + @OutputFileNameWithoutExtension + ' for CDR Records'

						set @ErrorDescription = 'SP_BSMedFormatterReprocessFileExceptions : '+ convert(varchar(30) ,getdate() , 120) +
													' : ' + @ErrorDescription

						Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath


						set @ResultFlag = 1

						GOTO ENDPROCESS

					End

			End

			set @ReprocessDiscardFileCreateFlag = 1 -- Need this flag to decide what needs to be rollback in case of exception

			--------------------------------------------------------------------
			-- **************** END CREATE DISCARD RECORD FILE ***************
			--------------------------------------------------------------------

End Try

Begin Catch

    set @ErrorDescription = 'ERROR !!! During Creation of output files for Processed , rejected and discarded CDR records.' + ERROR_MESSAGE()
  
    set @ErrorDescription = 'SP_BSMedFormatterReprocessFileExceptions : '+ convert(varchar(30) ,getdate() , 120) +
	                        ' : ' + @ErrorDescription
    Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

	set @ResultFlag = 1

	GOTO ENDPROCESS


End Catch

-----------------------------------------------------
-- START TEMPORARY CODE FOR THE PURPOSE OF DEBUGGING
-----------------------------------------------------

if not exists ( Select 1 from sysobjects where name  = 'Temp_AllProcessedRecords' and Xtype = 'U' )
Begin

		Select *
		into Temp_AllProcessedRecords
		from ##temp_MedFormatterRecords

End
Else
Begin

       -----------------------------------------------------------
	   -- First remove the old data set from the storage table
	   -----------------------------------------------------------

	   Delete tbl1
	   from Temp_AllProcessedRecords tbl1
	   inner join ##temp_MedFormatterRecords tbl2 on
	            tbl1.RecordID = tbl2.RecordID

       -----------------------------------------------------------
	   --  Insert the new representation for the records post
	   -- reprocessing
	   -----------------------------------------------------------

	   insert into Temp_AllProcessedRecords
	   Select * from ##temp_MedFormatterRecords


End

--------------------------------------------------------
-- Create the table to store the output records, in case
-- it does not exist
--------------------------------------------------------

if not exists ( Select 1 from sysobjects where name  = 'Temp_AllOutputRecords' and Xtype = 'U' )
Begin

		Select *
		into Temp_AllOutputRecords
		from ##temp_MedOutputFormatterRecords
		where 1=2

		----------------------------------------------------------
		-- Alter the table and add the enrichment fields as well
		----------------------------------------------------------

		Alter table Temp_AllOutputRecords Add INServiceLevelID Int
		Alter table Temp_AllOutputRecords Add INServiceLevel varchar(50)
		Alter table Temp_AllOutputRecords Add OUTServiceLevelID Int
		Alter table Temp_AllOutputRecords Add OUTServiceLevel varchar(50)
		Alter table Temp_AllOutputRecords Add EnrichedINCalledNumber varchar(100)
		Alter table Temp_AllOutputRecords Add EnrichedOutCalledNumber varchar(100)

End

-------------------------------------------------------------
-- Since this is reprocessing, ensure that the old record set
-- is deleted from the table
-------------------------------------------------------------

Delete tbl1
from Temp_AllOutputRecords tbl1
inner join ##temp_MedOutputFormatterRecords tbl2 on
	    tbl1.RecordID = tbl2.RecordID


--------------------------------------------------------------
-- Run the Pefixing enrichment process on the output records
-- to populate the service level and enriched called numbers
---------------------------------------------------------------

Begin Try

		set @ErrorDescription = NULL
		set @ResultFlag = 0

		Exec SP_BSMedCDRProcessingRulesMain @AbsoluteLogFilePath, @ErrorDescription Output , @ResultFlag Output


		if (@ResultFlag = 1)
		Begin
				 
				set @ErrorDescription = 'ERROR !!! During Application of prefixing rules on output CDR records.'

				set @ErrorDescription = 'SP_BSMedFormatterReprocessFileExceptions : '+ convert(varchar(30) ,getdate() , 120) +
										' : ' + @ErrorDescription
				Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

				set @ResultFlag = 1

				GOTO ENDPROCESS


		End 

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!! During Application of prefixing rules on output CDR records.' +  ERROR_MESSAGE()
  
		set @ErrorDescription = 'SP_BSMedFormatterReprocessFileExceptions : '+ convert(varchar(30) ,getdate() , 120) +
								' : ' + @ErrorDescription
		Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

		set @ResultFlag = 1

		GOTO ENDPROCESS


End Catch

---------------------------------------------------
-- END TEMPORARY CODE FOR THE PURPOSE OF DEBUGGING
---------------------------------------------------


-----------------------------------------------------------
-- If everything goes fine, then we need to update the 
-- statistics for output file as well as update the Mapping
-- table with the file name
------------------------------------------------------------

update tb_MedFormatterOutput
set TotalRecords = @TotalOutputRecordCount,
    [TotalProcessedRecords] = isnull(@TotalProcessedRecords,0),
	[TotalDiscardRecords] = isnull(@TotalDiscardRecords,0),
	[TotalRejectRecords] = isnull(@TotalRejectRecords,0),
	[TotalMinutes] = isnull(@TotalMinutes,0),
	[TotalProcessedMinutes] = isnull(@TotalProcessedMinutes,0),
	[TotalDiscardMinutes] = isnull(@TotalDiscardMinutes,0),
	[TotalRejectMinutes] = isnull(@TotalRejectMinutes,0),
    FileStatus = 'Processed'
where CDRFileID = @CDRFileID
and CdrFileName = @OutputFileNameWithoutExtension
and FileStatus = 'Reprocess'

set @StatisticsUpdateFlag = 1 -- Need this during rollback to understand what all needs to be reversed

--------------------------------------------------
-- Call the procedure to update the statistics 
-- related to reject and discard details
--------------------------------------------------

-----------------------------------------------------------------
-- Before updating the statistics keep the old statistics incase
-- there is exception
-----------------------------------------------------------------

Delete from tb_MedFormatterOutputDiscardDetails
where CDRFileID = @CDRFileID

Delete from tb_MedFormatterOutputRejectDetails
where CDRFileID = @CDRFileID

set @ErrorDescription = NULL
set @ResultFlag = 0

Exec SP_BSMedFormatterUpdateStatisticsDetails @CDRFileID,
                                              @AbsoluteLogFilePath,
                                              @ErrorDescription Output,
											  @ResultFlag Output

if ( @ResultFlag = 1 ) 
Begin

		set @ErrorDescription = 'ERROR !!! During update of reject and discard details for reprocessed file'
  
		set @ErrorDescription = 'SP_BSMedFormatterReprocessFileExceptions : '+ convert(varchar(30) ,getdate() , 120) +
								' : ' + @ErrorDescription
		Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

		set @ResultFlag = 1

		GOTO ENDPROCESS 

End

set @StatisticsDetailUpdateFlag = 1 -- Need this during rollback to understand what all needs to be reversed

ENDPROCESS:

-------------------------------------------------------------------------
-- If there have been any exceptions, then we need to rollback any changes 
-- performed
--------------------------------------------------------------------------

if (@ResultFlag = 1) 
Begin

            if ( @StatisticsUpdateFlag = 1 )
			Begin

					------------------------------------
					-- Update Statistics to old values
					------------------------------------

					update tb_MedFormatterOutput
					set TotalRecords = @TotalRecords,
						[TotalProcessedRecords] = isnull(@TotalOldProcessedRecords,0),
						[TotalDiscardRecords] = isnull(@TotalOldDiscardRecords,0),
						[TotalRejectRecords] = isnull(@TotalOldRejectRecords,0),
						[TotalMinutes] = isnull(@TotalOldMinutes,0),
						[TotalProcessedMinutes] = isnull(@TotalOldProcessedMinutes,0),
						[TotalDiscardMinutes] = isnull(@TotalOldDiscardMinutes,0),
						[TotalRejectMinutes] = isnull(@TotalOldRejectMinutes,0),
						FileStatus = 'Reprocess Error'
					where CDRFileID = @CDRFileID
					and CdrFileName = @OutputFileNameWithoutExtension
					and FileStatus in ( 'Reprocess' , 'Processed')

			End

			Else
			Begin

			        -----------------------------------------------
					-- Just change the status to reprocess error
					-----------------------------------------------

					update tb_MedFormatterOutput
					set FileStatus = 'Reprocess Error'
					where CDRFileID = @CDRFileID
					and CdrFileName = @OutputFileNameWithoutExtension
					and FileStatus in ( 'Reprocess' , 'Processed')

			End

			if (@StatisticsDetailUpdateFlag = 1 )
			Begin

					-------------------------------------------------------
					-- Update Reject and Discard Details to Old Values
					-------------------------------------------------------

					Delete from tb_MedFormatterOutputRejectDetails
					where CDRFileID = @CDRFileID

					Delete from tb_MedFormatterOutputDiscardDetails
					where CDRFileID = @CDRFileID

					Insert into tb_MedFormatterOutputRejectDetails
					Select * from #temp_MedFormatterRejectDetails

					Insert into tb_MedFormatterOutputDiscardDetails
					Select * from #temp_MedFormatterDiscardDetails

			End

			if ( @ReprocessOutputFileCreateFlag = 1 )
			Begin

					------------------------------------------------------
					-- Delete the output file, if created in the system
					------------------------------------------------------

					set @FileExists = 0

					Exec master..xp_fileexist  @AbsoluteOutputFileName , @FileExists output 

					If (@FileExists = 1)
					Begin

							set @Command = 'del ' + '"'+@AbsoluteOutputFileName +'"'
							--print @Command 

							Exec master..xp_cmdshell @Command

					End

					--------------------------------------------------------------
					-- Rename any previous instance of the OUTPUT file if exists
					--------------------------------------------------------------

					set @FileExists = 0

					Exec master..xp_fileexist  @AbsoluteOldOutputFileName , @FileExists output 

					If (@FileExists = 1)
					Begin

			        
							set @Command = 'ren ' + '"'+@AbsoluteOldOutputFileName +'"' + ' ' + @OutputFileName
							--print @Command 

							Exec master..xp_cmdshell @Command

					End

			End

			if (@ReprocessRejectFileCreateFlag =  1)
			Begin

					----------------------------------------------------------
					-- Delete the Reject file, if created in the system
					----------------------------------------------------------

					set @FileExists = 0

					Exec master..xp_fileexist  @AbsoluteRejectFileName , @FileExists output 

					If (@FileExists = 1)
					Begin

							set @Command = 'del ' + '"'+ @AbsoluteRejectFileName +'"'
							--print @Command 

							Exec master..xp_cmdshell @Command

					End

					--------------------------------------------------------------
					-- Rename any previous instance of the Reject file if exists
					--------------------------------------------------------------

					set @FileExists = 0

					Exec master..xp_fileexist  @AbsoluteOldRejectFileName , @FileExists output 

					If (@FileExists = 1)
					Begin

							set @Command = 'ren ' + '"'+@AbsoluteOldRejectFileName +'"' + ' ' + @OutputFileNameWithoutExtension + '.Reject'
							--print @Command 

							Exec master..xp_cmdshell @Command

					End

			End

			if (@ReprocessDiscardFileCreateFlag = 1)
			Begin

					----------------------------------------------------------
					-- Delete the Discard file, if created in the system
					----------------------------------------------------------

					set @FileExists = 0

					Exec master..xp_fileexist  @AbsoluteDiscardFileName , @FileExists output 

					If (@FileExists = 1)
					Begin

							set @Command = 'del ' + '"'+ @AbsoluteDiscardFileName +'"'
							--print @Command 

							Exec master..xp_cmdshell @Command

					End

					--------------------------------------------------------------
					-- Rename any previous instance of the DISCARD file if exists
					--------------------------------------------------------------

					set @FileExists = 0

					Exec master..xp_fileexist  @AbsoluteOldDiscardFileName , @FileExists output 

					If (@FileExists = 1)
					Begin

							set @Command = 'ren ' + '"'+ @AbsoluteOldDiscardFileName +'"' + ' ' + @OutputFileNameWithoutExtension + '.Discard'
							--print @Command 

							Exec master..xp_cmdshell @Command

					End

			End

		
End


if exists (select 1 from sysobjects where xtype = 'U' and name = @OutputFileNameWithoutExtension )
	Exec('Drop table ' + @OutputFileNameWithoutExtension )

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..##temp_MedFormatterRecords') )
		Drop table ##temp_MedFormatterRecords

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..##temp_MedOutputFormatterRecords') )
		Drop table ##temp_MedOutputFormatterRecords

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_MedFormatterDiscardDetails') )
		Drop table #temp_MedFormatterDiscardDetails

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_MedFormatterRejectDetails') )
		Drop table #temp_MedFormatterRejectDetails

GO
