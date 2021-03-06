USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMedFormatterCreateFile_Axiata_20181115]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSMedFormatterCreateFile_Axiata_20181115]
(
    @CDRFileName varchar(500),
	@OutputFilePath varchar(500),
	@RejectFilePath varchar(500),
	@DuplicateFilePath varchar(500),
	@RowDelimiter varchar(50),
	@FieldDelimiter varchar(50),
	@CDRFileExtension varchar(100),
	@LogFileName varchar(500),
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

-- Example of Input to the procedure

--set @CDRFileName = 'G:\Uclick_Product_Suite\uClickFacilitate\MedFormatter\Temp\avh01-5_-_542.20180708_-_1146+0800.CDR'
--set @OutputFilePath = 'G:\Uclick_Product_Suite\uClickFacilitate\MedFormatter\Output'
--set @RejectFilePath = 'G:\Uclick_Product_Suite\uClickFacilitate\MedFormatter\Reject'
--set @DuplicateFilePath = 'G:\Uclick_Product_Suite\uClickFacilitate\MedFormatter\Duplicate'
--set @RowDelimiter = '\n'
--set @FieldDelimiter = '|'
--set @CDRFileExtension = '.CDR'
--set @LogFileName = 'F:\Uclick_Product_Suite\uClickFacilitate\Logs\MedFormatter.Log'

Declare	@SQLStr varchar(2000),
		@FileExists int,
		@cmd varchar(2000),
		@Remarks varchar(2000),
		@CDRFileNameWithoutExtension varchar(500),
		@CDRFileNameWithoutPath varchar(500),
		@OutputFileName varchar(500),
		@IntermediateFileNameWithFullPath varchar(500),
		@RejectFileName varchar(1000),
		@DuplicateFileName varchar(1000)

---------------------------------------------------------------
-- Extract just the CDR file name without the extension & Path
---------------------------------------------------------------

set @CDRFileNameWithoutPath = reverse(substring(reverse(@CDRFileName) , 1 , charindex('\' , reverse(@CDRFileName)) - 1))
set @CDRFileNameWithoutExtension = substring(@CDRFileNameWithoutPath , 1 , len(@CDRFileNameWithoutPath) - len(@CDRFileExtension))

--select @CDRFileNameWithoutPath as CDRFileNameWithoutPath , @CDRFileNameWithoutExtension as CDRFileNameWithoutExtension

---------------------------------------------
-- Construct the name of the output file
---------------------------------------------

if (right(@OutputFilePath , 1) <> '\')
	set @OutputFilePath = @OutputFilePath + '\'

set @OutputFileName = @OutputFilePath + @CDRFileNameWithoutPath

--select @OutputFileName as OutputFileName

---------------------------------------------
-- Construct the name of the Intermediate file
---------------------------------------------

set @IntermediateFileNameWithFullPath = @OutputFilePath + @CDRFileNameWithoutExtension + '.TEMP'

--select @IntermediateFileNameWithFullPath as IntermediateFileName

-------------------------------------------------------
-- Construct the name of Reject and Duplicate CDR Files
-------------------------------------------------------

if (right(@RejectFilePath , 1) <> '\')
	set @RejectFilePath = @RejectFilePath + '\'

if (right(@DuplicateFilePath , 1) <> '\')
	set @DuplicateFilePath = @DuplicateFilePath + '\'

set @RejectFileName = @RejectFilePath + @CDRFileNameWithoutExtension + '.Rej'
set @DuplicateFileName = @DuplicateFilePath + @CDRFileNameWithoutExtension + '.Dup'

--select @RejectFileName as RejectFileName, @DuplicateFileName as DuplicateFileName

-----------------------------------------------------------
-- Delete the intermediate output file, if it already exists
-----------------------------------------------------------

set @FileExists = 0

Exec master..xp_fileexist @IntermediateFileNameWithFullPath , @FileExists output

if ( @FileExists = 1 )
Begin

	set @cmd = 'Del ' + @IntermediateFileNameWithFullPath 
	Exec master..xp_cmdshell @cmd

End

------------------------------------------------
-- Delete the output file, if it already exists
------------------------------------------------

set @FileExists = 0

Exec master..xp_fileexist @OutputFileName , @FileExists output

if ( @FileExists = 1 )
Begin

	set @cmd = 'Del ' + @OutputFileName 
	Exec master..xp_cmdshell @cmd

End

------------------------------------------------
-- Delete the Reject file, if it already exists
------------------------------------------------

set @FileExists = 0

Exec master..xp_fileexist @RejectFileName , @FileExists output

if ( @FileExists = 1 )
Begin

	set @cmd = 'Del ' + @RejectFileName 
	Exec master..xp_cmdshell @cmd

End

------------------------------------------------
-- Delete the Duplicate file, if it already exists
------------------------------------------------

set @FileExists = 0

Exec master..xp_fileexist @DuplicateFileName , @FileExists output

if ( @FileExists = 1 )
Begin

	set @cmd = 'Del ' + @DuplicateFileName 
	Exec master..xp_cmdshell @cmd

End

------------------------------------------------------
-- Create an entry in the statistics table, or update
-- the entry, which already exists
------------------------------------------------------

if exists ( select 1 from tb_MedFormatterStatistics where CDRFileName = @CDRFileNameWithoutExtension)
Begin



		update tb_MedFormatterStatistics
		set TotalRecords = 0,
			TotalProcessedRecords = 0,
			TotalDuplicateRecords = 0,
			TotalRejectRecords = 0,
			TotalMinutes = 0,
			TotalProcessedMinutes = 0,
			TotalDuplicateMinutes = 0,
			TotalRejectMinutes = 0,
			FileStatus = 'Processing',
			Remarks = NULL
		where CDRFileName =  @CDRFileNameWithoutExtension

		-- Remove records from the DUP Check tables since are are reprocessing the file

		Exec SP_BSFormatterRemoveRecordsFromDupCheckSchema @CDRFileNameWithoutExtension,
		                                                   @LogFileName,
														   @ErrorDescription Output,
														   @ResultFlag
        if(@ResultFlag = 1)
		Begin

			set @ErrorDescription = 'ERROR !!! Deleting records for CDR file from Duplicate Check tables'
  
			set @ErrorDescription = 'SP_BSMedFormatterCreateFile : '+ convert(varchar(30) ,getdate() , 120) +
									' : ' + @ErrorDescription
			Exec SP_LogMessage @ErrorDescription , @LogFileName

			set @ResultFlag = 1

			GOTO ENDPROCESS 

		End

		
End

else
Begin

		insert into tb_MedFormatterStatistics
		(
			CDRFileName,
			TotalRecords,
			TotalProcessedRecords,
			TotalDuplicateRecords,
			TotalRejectRecords,
			TotalMinutes,
			TotalProcessedMinutes,
			TotalDuplicateMinutes,
			TotalRejectMinutes,
			FileStatus,
			Remarks
		)
		values
		(
			@CDRFileNameWithoutExtension,
			0,
			0,
			0,
			0,
			0,
			0,
			0,
			0,
			'Processing',
			NULL
		)


End

-------------------------------------------------------------
-- Create the schema as per the file definition of the input
-- and output file
--------------------------------------------------------------

Declare @FileDefinitionID int,
		@OutputFileDefinitionID int,
		@InputFileTable varchar(500),
		@OutputFileTable varchar(500)

-- Get the schema definition for the input file table

select @FileDefinitionID = convert(int , tbl1.ConfigValue)
from tb_Config tbl1
inner join tb_AccessScope tbl2 on tbl1.AccessScopeID = tbl2.AccessScopeID
where tbl2.AccessScopeName = 'MedFormatter'
and tbl1.Configname = 'IntermediateFormatterFileDefinition'

if ( @FileDefinitionID is NULL )
Begin

		set @ErrorDescription = 'ERROR !!! Configuration missing for the intermediate CDR File Definition (IntermediateFormatterFileDefinition)'
  
		set @ErrorDescription = 'SP_BSMedFormatterCreateFile : '+ convert(varchar(30) ,getdate() , 120) +
								' : ' + @ErrorDescription
		Exec SP_LogMessage @ErrorDescription , @LogFileName

		set @ResultFlag = 1

		GOTO ENDPROCESS 

End


Begin Try


		-- Create the table for importing the input file contents into the
		-- database

		set @ResultFlag = 0
		set @ErrorDescription = NULL

		set @InputFileTable = 'TempFormatterInputFile_' + replace(replace(replace(convert(varchar(20), getdate(), 120), ' ', ''), '-' , ''), ':' , '')

		if exists (select 1 from sysobjects where xtype = 'U' and name = @InputFileTable )
				Exec('Drop table ' + @InputFileTable )


		Exec SP_BSMedFormatterDynamicTableCreate @FileDefinitionID , @InputFileTable,
												 @LogFileName , @ErrorDescription Output,
												 @ResultFlag Output

		if ( @ResultFlag = 1 ) 
		Begin

				set @ErrorDescription = 'ERROR !!! During creation of table for storing input file records'
  
				set @ErrorDescription = 'SP_BSMedFormatterCreateFile : '+ convert(varchar(30) ,getdate() , 120) +
										' : ' + @ErrorDescription
				Exec SP_LogMessage @ErrorDescription , @LogFileName

				set @ResultFlag = 1

				GOTO ENDPROCESS 

		End

		-- Create a temp table based on the input file table definition
		-- for further processing

		--Exec('Select * from ' + @InputFileTable )

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..##temp_MedFormatterRecords') )
			Drop table ##temp_MedFormatterRecords

		Exec('Select * into ##temp_MedFormatterRecords from ' + @InputFileTable)
		Exec('Drop table ' + @InputFileTable )

		--select * from ##temp_MedFormatterRecords


		--------------------------------------------------------------------------
		-- Bulk Upload the contents of the input file into the Dynamic table
		--------------------------------------------------------------------------

		Select	@SQLStr = 'Bulk Insert ##temp_MedFormatterRecords From ' 
						  + '''' + @CDRFileName +'''' + ' WITH (
						  FIELDTERMINATOR  = ''' + @FieldDelimiter + ''','+
						  'ROWTERMINATOR    = ''' + @RowDelimiter + ''''+')'

		--print @SQLStr
		Exec (@SQLStr)


		--Select 'Debug : After uploading the input File into temp table' as status
		--select * from ##temp_MedFormatterRecords

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!! During import of input file records.' + ERROR_MESSAGE()
  
		set @ErrorDescription = 'SP_BSMedFormatterCreateFile : '+ convert(varchar(30) ,getdate() , 120) +
								' : ' + @ErrorDescription
		Exec SP_LogMessage @ErrorDescription , @LogFileName

		set @ResultFlag = 1

		GOTO ENDPROCESS

End Catch


-- Get the schema definition for the Output File table

select @OutputFileDefinitionID = convert(int , tbl1.ConfigValue)
from tb_Config tbl1
inner join tb_AccessScope tbl2 on tbl1.AccessScopeID = tbl2.AccessScopeID
where tbl2.AccessScopeName = 'MedFormatter'
and tbl1.Configname = 'OutFormatterFileDefinition'

if ( @OutputFileDefinitionID is NULL )
Begin

		set @ErrorDescription = 'ERROR !!! Configuration missing for the Output CDR File Definition (OutFormatterFileDefinition)'
  
		set @ErrorDescription = 'SP_BSMedFormatterCreateFile : '+ convert(varchar(30) ,getdate() , 120) +
								' : ' + @ErrorDescription
		Exec SP_LogMessage @ErrorDescription , @LogFileName

		set @ResultFlag = 1

		GOTO ENDPROCESS 

End

Begin Try


		-- Create the table for importing the input file contents into the
		-- database

		set @ResultFlag = 0
		set @ErrorDescription = NULL

		set @OutputFileTable = 'TempFormatterOutputFile_' + replace(replace(replace(convert(varchar(20), getdate(), 120), ' ', ''), '-' , ''), ':' , '')

		if exists (select 1 from sysobjects where xtype = 'U' and name = @OutputFileTable )
				Exec('Drop table ' + @OutputFileTable )


		Exec SP_BSMedFormatterDynamicTableCreate @OutputFileDefinitionID , @OutputFileTable,
												 @LogFileName , @ErrorDescription Output,
												 @ResultFlag Output

		if ( @ResultFlag = 1 ) 
		Begin

				set @ErrorDescription = 'ERROR !!! During creation of table for storing output file records'
  
				set @ErrorDescription = 'SP_BSMedFormatterCreateFile : '+ convert(varchar(30) ,getdate() , 120) +
										' : ' + @ErrorDescription
				Exec SP_LogMessage @ErrorDescription , @LogFileName

				set @ResultFlag = 1

				GOTO ENDPROCESS 

		End

		-- Create a temp table based on the output file table definition
		-- for further processing

		--Exec('Select * from ' + @OutputFileTable )

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..##temp_MedFormatterOutputRecords') )
			Drop table ##temp_MedFormatterOutputRecords

		Exec('Select * into ##temp_MedFormatterOutputRecords from ' + @OutputFileTable)
		Exec('Drop table ' + @OutputFileTable )

		--select * from ##temp_MedFormatterOutputRecords


End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!! During Creation of schema for output formatter records.' + ERROR_MESSAGE()
  
		set @ErrorDescription = 'SP_BSMedFormatterCreateFile : '+ convert(varchar(30) ,getdate() , 120) +
								' : ' + @ErrorDescription
		Exec SP_LogMessage @ErrorDescription , @LogFileName

		set @ResultFlag = 1

		GOTO ENDPROCESS

End Catch

----------------------------------------------------
-- Add a RecordStatus field in the output file
-- schema to track if the record needs to be rejected,
-- processed or moved to duplicate
-----------------------------------------------------

Alter table ##temp_MedFormatterOutputRecords Add RecordStatus varchar(20)

------------------------------------------------------------
-- Add RecordID field to both temp output and input tables
------------------------------------------------------------

Alter table ##temp_MedFormatterOutputRecords Add RecordID int 
Alter table ##temp_MedFormatterRecords Add RecordID int identity(1,1)

--select * from ##temp_MedFormatterOutputRecords
--select * from ##temp_MedFormatterRecords

---------------------------------------------------------------------
-- Call the CUSTOM process for converting the information present in
-- the input file records to Output file records
---------------------------------------------------------------------

Begin Try

		Exec SP_BSMedFormatterCustomOutputEnrichment @LogFileName , 
													 @ErrorDescription Output,
												     @ResultFlag Output

		if ( @ResultFlag = 1 ) 
		Begin

				set @ErrorDescription = 'ERROR !!! During creation of output records from input record info'
  
				set @ErrorDescription = 'SP_BSMedFormatterCreateFile : '+ convert(varchar(30) ,getdate() , 120) +
										' : ' + @ErrorDescription
				Exec SP_LogMessage @ErrorDescription , @LogFileName

				set @ResultFlag = 1

				GOTO ENDPROCESS 

		End

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!! During creation of output records from input record info.' + ERROR_MESSAGE()
  
		set @ErrorDescription = 'SP_BSMedFormatterCreateFile : '+ convert(varchar(30) ,getdate() , 120) +
								' : ' + @ErrorDescription
		Exec SP_LogMessage @ErrorDescription , @LogFileName

		set @ResultFlag = 1

		GOTO ENDPROCESS

End Catch

--Select 'Debug: Publishing the Output records.' as status
--select * from ##temp_MedFormatterOutputRecords where RecordStatus is NOT NULL

------------------------------------------------------------------------
-- Check for Duplicate Records within the CDR File and across all the
-- other unique CDR records
------------------------------------------------------------------------

-----------------------------------------------
-- Block the duplicate check piece of
-- code till the Session-Id based solution
-- is not analyzed and developed
-----------------------------------------------

--Begin Try

--		Exec SP_BSMedFormatterCustomDuplicateCheck   @CDRFileNameWithoutExtension,  
--													 @LogFileName , 
--													 @ErrorDescription Output,
--												     @ResultFlag Output

--		if ( @ResultFlag = 1 ) 
--		Begin

--				set @ErrorDescription = 'ERROR !!! During duplicate check of CDR Records'
  
--				set @ErrorDescription = 'SP_BSMedFormatterCreateFile : '+ convert(varchar(30) ,getdate() , 120) +
--										' : ' + @ErrorDescription
--				Exec SP_LogMessage @ErrorDescription , @LogFileName

--				set @ResultFlag = 1

--				GOTO ENDPROCESS 

--		End

--End Try

--Begin Catch

--		set @ErrorDescription = 'ERROR !!! During during duplicate check of CDR records.' + ERROR_MESSAGE()
  
--		set @ErrorDescription = 'SP_BSMedFormatterCreateFile : '+ convert(varchar(30) ,getdate() , 120) +
--								' : ' + @ErrorDescription
--		Exec SP_LogMessage @ErrorDescription , @LogFileName

--		set @ResultFlag = 1

--		GOTO ENDPROCESS

--End Catch

-------------------------------------------
-- Get all the statistcs for the CDR file 
-------------------------------------------

Declare @TotalRecords int,
		@TotalProcessedRecords int ,
		@TotalRejectRecords int,
		@TotalDuplicateRecords int,
		@TotalMinutes Decimal(19,2),
		@TotalProcessedMinutes Decimal(19,2),
		@TotalRejectMinutes Decimal(19,2),
		@TotalDuplicateMinutes Decimal(19,2)

Begin Try

		Exec SP_BSMedFormatterCustomGetStatistics  	@TotalRecords Output,
													@TotalProcessedRecords Output,
													@TotalRejectRecords Output,
													@TotalDuplicateRecords Output,
													@TotalMinutes Output,
													@TotalProcessedMinutes Output,
													@TotalRejectMinutes Output,
													@TotalDuplicateMinutes Output

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!! During Calculation of file processing statistics.' + ERROR_MESSAGE()
  
		set @ErrorDescription = 'SP_BSMedFormatterCreateFile : '+ convert(varchar(30) ,getdate() , 120) +
								' : ' + @ErrorDescription
		Exec SP_LogMessage @ErrorDescription , @LogFileName

		set @ResultFlag = 1

		GOTO ENDPROCESS

End Catch

--Select 'Debug: Publish the File Processing Statistics' as status
--select  @TotalRecords as TotalRecords,
--		@TotalProcessedRecords as TotalProcessedRecords,
--		@TotalRejectRecords as TotalRejectRecords,
--		@TotalDuplicateRecords as TotalDuplicateRecords,
--		@TotalMinutes as TotalMinutes ,
--		@TotalProcessedMinutes as TotalProcessedMinutes,
--		@TotalRejectMinutes as TotalRejectMinutes,
--		@TotalDuplicateMinutes as TotalDuplicateMinutes

-------------------------------------------------------------------
-- Create the Output, Reject and Duplicate files with the relevant
-- CDR records
-------------------------------------------------------------------

Declare @RejectRecordsSchema varchar(100),
        @ProcessRecordsSchema varchar(100),
		@DuplicateRecordsSchema varchar(100),
		@SchemaName varchar(200),
		@ServerName  varchar(200)


set @RejectRecordsSchema = 'TempOutputReject_'+ replace(replace(replace(convert(varchar(20) , getdate(), 120), ' ',''), ':', ''), '-', '')
set @ProcessRecordsSchema = 'TempOutputProcess_'+ replace(replace(replace(convert(varchar(20) , getdate(), 120), ' ',''), ':', ''), '-', '')
set @DuplicateRecordsSchema = 'TempOutputDuplicate_'+ replace(replace(replace(convert(varchar(20) , getdate(), 120), ' ',''), ':', ''), '-', '')

Begin Try

		------------------
		-- REJECT CDR FILE
		------------------
		if (@TotalRejectRecords > 0 )
		Begin

				-- Select all the reject records
				if exists (select 1 from sysobjects where xtype = 'U' and name = @RejectRecordsSchema )
					Exec('Drop table ' + @RejectRecordsSchema )

				set @SQLStr = 'select tbl1.* ' + char(10)+
							  'into ' + @RejectRecordsSchema + char(10) +
							  'from ##temp_MedFormatterRecords tbl1' + char(10) +
							  'inner join ##temp_MedFormatterOutputRecords tbl2' + char(10) +
							  'on tbl1.RecordID = tbl2.RecordID' + char(10) +
							  'where tbl2.RecordStatus = ''REJECT'''

				Exec(@SQLStr)

				-- Drop the RecordID field from the schema
				Exec('Alter table ' + @RejectRecordsSchema + ' Drop column RecordID')

				--Exec('Select * from ' + @RejectRecordsSchema)

				-- Publish the records to the output file
				set @SchemaName = db_name() + '.dbo.' + @RejectRecordsSchema
				set @ServerName = @@SERVERNAME

				set @SQLStr = 'bcp "select * from '+ @SchemaName +'" queryout ' + '"'+ @RejectFileName + '"' + ' -c -t "'+ @FieldDelimiter +'" -r"'+ @RowDelimiter +'" -T -S '+ @ServerName

				Exec master..xp_cmdshell @SQLStr

				-- Check to see if the Reject file has been created or not

				set @FileExists = 0

				Exec master..xp_fileexist @RejectFileName , @FileExists output  

				if ( @FileExists <> 1 )
				Begin

 						set @ErrorDescription = 'SP_BSMedFormatterCreateFile : '+ convert(varchar(30) ,getdate() , 120) +
												' : ' + 'ERROR !!! Reject CDRs output file (' + @RejectFileName + ') not created'
		
						Exec SP_LogMessage @ErrorDescription , @LogFileName
						set @ResultFlag = 1
						GOTO ENDPROCESS

				End 

		End

		------------------------
		-- DUPLICATE CDR FILE
		------------------------
		if (@TotalDuplicateRecords > 0 )
		Begin

				-- Select all the duplicate records
				if exists (select 1 from sysobjects where xtype = 'U' and name = @DuplicateRecordsSchema )
					Exec('Drop table ' + @DuplicateRecordsSchema )

				set @SQLStr = 'select tbl1.* ' + char(10)+
							  'into ' + @DuplicateRecordsSchema + char(10) +
							  'from ##temp_MedFormatterRecords tbl1' + char(10) +
							  'inner join ##temp_MedFormatterOutputRecords tbl2' + char(10) +
							  'on tbl1.RecordID = tbl2.RecordID' + char(10) +
							  'where tbl2.RecordStatus = ''DUPLICATE'''

				Exec(@SQLStr)

				-- Drop the RecordID field from the schema
				Exec('Alter table ' + @DuplicateRecordsSchema + ' Drop column RecordID')

				--Exec('Select * from ' + @DuplicateRecordsSchema)

				-- Publish the records to the output file
				set @SchemaName = db_name() + '.dbo.' + @DuplicateRecordsSchema
				set @ServerName = @@SERVERNAME

				set @SQLStr = 'bcp "select * from '+ @SchemaName +'" queryout ' + '"'+ @DuplicateFileName + '"' + ' -c -t "'+ @FieldDelimiter +'" -r"'+ @RowDelimiter +'" -T -S '+ @ServerName

				Exec master..xp_cmdshell @SQLStr

				-- Check to see if the Duplicate file has been created or not

				set @FileExists = 0

				Exec master..xp_fileexist @DuplicateFileName , @FileExists output  

				if ( @FileExists <> 1 )
				Begin

 						set @ErrorDescription = 'SP_BSMedFormatterCreateFile : '+ convert(varchar(30) ,getdate() , 120) +
												' : ' + 'ERROR !!! Duplicate CDRs output file (' + @DuplicateFileName + ') not created'
		
						Exec SP_LogMessage @ErrorDescription , @LogFileName
						set @ResultFlag = 1
						GOTO ENDPROCESS

				End 

		End

		------------------------
		-- PROCESSED CDR FILE
		------------------------
		if (@TotalProcessedRecords > 0 )
		Begin

				-- Select all the processed records
				if exists (select 1 from sysobjects where xtype = 'U' and name = @ProcessRecordsSchema )
					Exec('Drop table ' + @ProcessRecordsSchema )

				set @SQLStr = 'select tbl2.* ' + char(10)+
							  'into ' + @ProcessRecordsSchema + char(10) +
							  'from ##temp_MedFormatterRecords tbl1' + char(10) +
							  'inner join ##temp_MedFormatterOutputRecords tbl2' + char(10) +
							  'on tbl1.RecordID = tbl2.RecordID' + char(10) +
							  'where tbl2.RecordStatus is NULL'

				Exec(@SQLStr)

				-- Drop the RecordID field from the schema
				Exec('Alter table ' + @ProcessRecordsSchema + ' Drop column RecordID')

				--Exec('Select * from ' + @ProcessRecordsSchema)

				-- Publish the records to the output file
				set @SchemaName = db_name() + '.dbo.' + @ProcessRecordsSchema
				set @ServerName = @@SERVERNAME

				set @SQLStr = 'bcp "select * from '+ @SchemaName +'" queryout ' + '"'+ @IntermediateFileNameWithFullPath + '"' + ' -c -t "," -r"\n" -T -S '+ @ServerName

				Exec master..xp_cmdshell @SQLStr

				-- Check to see if the output intermediate file has been created or not

				set @FileExists = 0

				Exec master..xp_fileexist @IntermediateFileNameWithFullPath , @FileExists output  

				if ( @FileExists <> 1 )
				Begin

 						set @ErrorDescription = 'SP_BSMedFormatterCreateFile : '+ convert(varchar(30) ,getdate() , 120) +
												' : ' + 'ERROR !!! Processed CDRs intermediate output file (' + @IntermediateFileNameWithFullPath + ') not created'
		
						Exec SP_LogMessage @ErrorDescription , @LogFileName
						set @ResultFlag = 1
						GOTO ENDPROCESS

				End 

		End

End Try

Begin Catch

 		set @ErrorDescription = 'SP_BSMedFormatterCreateFile : '+ convert(varchar(30) ,getdate() , 120) +
								' : ' + 'ERROR !!! During creation of reject , duplicate or intermediate output file.' + ERROR_MESSAGE()
		
		Exec SP_LogMessage @ErrorDescription , @LogFileName
		set @ResultFlag = 1
		GOTO ENDPROCESS

End Catch

---------------------------------------------------------
-- Once complete, rename the intermediate file to Output
-- file
---------------------------------------------------------

set @FileExists = 0

Exec master..xp_fileexist @IntermediateFileNameWithFullPath , @FileExists output

if ( @FileExists = 1 )
Begin

		set @cmd = 'Rename ' + '"' + @IntermediateFileNameWithFullPath + '"' + ' ' + '"' + @CDRFileNameWithoutPath + '"'
		print @cmd
		Exec master..xp_cmdshell @cmd

		-----------------------------------------------
		-- Check if renaming has been successful or not
		-----------------------------------------------

		set @FileExists = 0

		Exec master..xp_fileexist @OutputFileName , @FileExists output 

		if ( @FileExists <> 1 )
		Begin

 				set @ErrorDescription = 'SP_BSMedFormatterCreateFile : '+ convert(varchar(30) ,getdate() , 120) +
										' : ' + 'ERROR !!! While renaming Temp CDR file: : ' + @IntermediateFileNameWithFullPath + ' in output folder to output file'
				
				Exec SP_LogMessage @ErrorDescription , @LogFileName
				set @ResultFlag = 1
				GOTO ENDPROCESS
				     
		End


End

-----------------------------------------------
-- Delete the input CDR file after completion
-----------------------------------------------

set @cmd = 'Del ' + @CDRFileName 
Exec master..xp_cmdshell @cmd


ENDPROCESS:

-------------------------------------------------------
-- Depending on the Result Flag update the statistics
-- table with Failed or Completed state. Also update
-- the statistics
-------------------------------------------------------

if (@ResultFlag = 1)
Begin

		update tb_MedFormatterStatistics
		set TotalRecords = isnull(@TotalRecords,0),
			TotalProcessedRecords = isnull(@TotalProcessedRecords,0),
			TotalDuplicateRecords = isnull(@TotalDuplicateRecords,0),
			TotalRejectRecords = isnull(@TotalRejectRecords,0),
			TotalMinutes = isnull(@TotalMinutes,0),
			TotalProcessedMinutes = isnull(@TotalProcessedMinutes,0),
			TotalDuplicateMinutes = isnull(@TotalDuplicateMinutes,0),
			TotalRejectMinutes = isnull(@TotalRejectMinutes,0),
			FileStatus = 'Failed',
			Remarks = @ErrorDescription
		where CDRFileName =  @CDRFileNameWithoutExtension

		-----------------------------------------------------------
		-- Delete the intermediate output file, if it already exists
		-----------------------------------------------------------

		set @FileExists = 0

		Exec master..xp_fileexist @IntermediateFileNameWithFullPath , @FileExists output

		if ( @FileExists = 1 )
		Begin

			set @cmd = 'Del ' + @IntermediateFileNameWithFullPath 
			Exec master..xp_cmdshell @cmd

		End

		-----------------------------------------------------------
		-- Delete the Final output file, if it already exists
		-----------------------------------------------------------

		set @FileExists = 0

		Exec master..xp_fileexist @OutputFileName , @FileExists output

		if ( @FileExists = 1 )
		Begin

			set @cmd = 'Del ' + @OutputFileName 
			Exec master..xp_cmdshell @cmd

		End

		------------------------------------------------
		-- Delete the Reject file, if it already exists
		------------------------------------------------

		set @FileExists = 0

		Exec master..xp_fileexist @RejectFileName , @FileExists output

		if ( @FileExists = 1 )
		Begin

			set @cmd = 'Del ' + @RejectFileName 
			Exec master..xp_cmdshell @cmd

		End

		------------------------------------------------
		-- Delete the Duplicate file, if it already exists
		------------------------------------------------

		set @FileExists = 0

		Exec master..xp_fileexist @DuplicateFileName , @FileExists output

		if ( @FileExists = 1 )
		Begin

			set @cmd = 'Del ' + @DuplicateFileName 
			Exec master..xp_cmdshell @cmd

End


End

else
Begin

		update tb_MedFormatterStatistics
		set TotalRecords = isnull(@TotalRecords,0),
			TotalProcessedRecords = isnull(@TotalProcessedRecords,0),
			TotalDuplicateRecords = isnull(@TotalDuplicateRecords,0),
			TotalRejectRecords = isnull(@TotalRejectRecords,0),
			TotalMinutes = isnull(@TotalMinutes,0),
			TotalProcessedMinutes = isnull(@TotalProcessedMinutes,0),
			TotalDuplicateMinutes = isnull(@TotalDuplicateMinutes,0),
			TotalRejectMinutes = isnull(@TotalRejectMinutes,0),
			FileStatus = 'Completed',
			Remarks = NULL
		where CDRFileName =  @CDRFileNameWithoutExtension


End


if exists (select 1 from sysobjects where xtype = 'U' and name = @InputFileTable )
		Exec('Drop table ' + @InputFileTable )

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..##temp_MedFormatterRecords') )
		Drop table ##temp_MedFormatterRecords

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..##temp_MedFormatterOutputRecords') )
		Drop table ##temp_MedFormatterOutputRecords

if exists (select 1 from sysobjects where xtype = 'U' and name = @OutputFileTable )
		Exec('Drop table ' + @OutputFileTable )

if exists (select 1 from sysobjects where xtype = 'U' and name = @RejectRecordsSchema )
		Exec('Drop table ' + @RejectRecordsSchema )

if exists (select 1 from sysobjects where xtype = 'U' and name = @DuplicateRecordsSchema )
		Exec('Drop table ' + @DuplicateRecordsSchema )

if exists (select 1 from sysobjects where xtype = 'U' and name = @ProcessRecordsSchema )
		Exec('Drop table ' + @ProcessRecordsSchema )
GO
