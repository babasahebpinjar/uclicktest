USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSConverterParseFile_OldLogic]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--Create Procedure SP_BSConverterParseFile As

CREATE Procedure [dbo].[SP_BSConverterParseFile_OldLogic] As

Declare @CDRFileName varchar(500) = 'G:\Uclick_Product_Suite\uClickFacilitate\MedCollector\Temp\avh01-5_-_454.20180707_-_1352+0800.CDR',
        @KeyFieldsFile varchar(500) = 'C:\Uclick_Product_Suite\uClickFacilitate\Format\KeyFields.txt',
		@OutputFilePath varchar(500) = 'G:\Uclick_Product_Suite\uClickFacilitate\MedConverter\Output\',
		@CDRFileExtension varchar(100) = '.CDR',
		@LogFileName varchar(500) = 'F:\Uclick_Product_Suite\uClickFacilitate\Logs\MedConverter.log',
		@ErrorMsgStr varchar(2000),
		@ResultFlag int

Declare @RowTerminator varchar(20) = '\n',
		@SQLStr varchar(2000),
		@ImportError varchar(1000),
		@TotalCDRRecordsInFile int,
		@TotalCDRRecordsCalculate int,
		@FileExists int,
		@cmd varchar(2000),
		@Remarks varchar(2000),
		@CDRFileNameWithoutExtension varchar(500),
		@CDRFileNameWithoutPath varchar(500),
		@OutputFileName varchar(500),
		@IntermediateFileNameWithFullPath varchar(500)

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

------------------------------------------------------
-- Create an entry in the statistics table, or update
-- the entry, which already exists
------------------------------------------------------

if exists ( select 1 from tb_MedConverterStatistics where CDRFileName = @CDRFileNameWithoutExtension)
Begin

		update tb_MedConverterStatistics
		set ProcessStartTime = getdate(),
			TotalRecords = 0,
			TotalOutputRecords = 0,
			TotalProcessTime = 0,
			FileStatus = 'Processing',
			Remarks = NULL
		where CDRFileName =  @CDRFileNameWithoutExtension

End

else
Begin

		insert into tb_MedConverterStatistics
		(
			CDRFileName,
			TotalRecords,
			TotalOutputRecords,
			ProcessStartTime,
			TotalProcessTime,
			FileStatus,
			Remarks
		)
		values
		(
			@CDRFileNameWithoutExtension,
			0,
			0,
			getdate(),
			0,
			'Processing',
			NULL
		)


End


---------------------------------------------------
-- Upload the Key Fields file into the database
----------------------------------------------------

-- Create a temporary table to hold the contents of the Key Fields File

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempKeyFieldsData') )	
	Drop table #TempKeyFieldsData

Create table #TempKeyFieldsData (FieldName varchar(500))

Begin Try

	Select	@SQLStr = 'Bulk Insert  #TempKeyFieldsData '+ ' From ' 
					+ '''' + @KeyFieldsFile +'''' + ' WITH ('+
					'ROWTERMINATOR    = ''' + @RowTerminator + ''''+')'

	--print @SQLStr
	Exec (@SQLStr)


End Try

Begin Catch

	set @ErrorMsgStr = 'SP_BSConverterParseFile : '+ convert(varchar(30) ,getdate() , 120) +
								' : ' + 'ERROR !!!Uploading the key fields file (' + @KeyFieldsFile +').' + ERROR_MESSAGE()

    set @Remarks = 'ERROR !!!Uploading the key fields file (' + @KeyFieldsFile +').'
	set @ResultFlag = 1
	Exec SP_LogMessage @ErrorMsgStr , @LogFileName
	GOTO ENDPROCESS

End Catch

-- Make sure to remove all the spaces in front and end of key field names

update #TempKeyFieldsData
set FieldName = rtrim(ltrim(FieldName))

--Select 'Debug: Publish the Key Fileds file post upload' as status
--select * from #TempKeyFieldsData

-- Add a Identity Field to the KeyFields Table for maintaining an order

Alter table #TempKeyFieldsData Add KeyFieldsID int identity(1,1)

----------------------------------------------------------------------------
-- Create a temporary table to hold the contents of the CDR file in database
-------------------------------------------------------------------------------

Declare @CDRFileTable varchar(100)

-- Create at temp table with a unique name

set @CDRFileTable = 'TempCDRFileData_' + replace(replace(replace(convert(varchar(20), getdate(),120), ' ', ''),'-' , ''), ':', '')
set @SQLStr = 'Create table ' + @CDRFileTable + '( RecordData varchar(2000))'
Exec(@SQLStr)

-- Check if the Temp table for CDR file upload has been created or not

if not exists (select 1 from sysobjects where name = @CDRFileTable and xtype = 'U')
Begin

	set @ErrorMsgStr = 'SP_BSConverterParseFile : '+ convert(varchar(30) ,getdate() , 120) +
								' : '+'ERROR !!! Creating the temp table for holding the CDR file unparsed records'

    set @Remarks = 'ERROR !!! Creating the temp table for holding the CDR file unparsed records'
	set @ResultFlag = 1
	Exec SP_LogMessage @ErrorMsgStr , @LogFileName
	GOTO ENDPROCESS

End

--Select 'Debug: Check structure of temp table that holds CDR file records' as status
--Exec('Select * from '+ @CDRFileTable)

------------------------------------------------------------
-- Use the bcp command to upload the contents of the file
-- into the table
------------------------------------------------------------

-- Build the essential parameters to call the bcp command

Declare @SchemaName varchar(200),
        @ServerName varchar(200)

set @SchemaName = db_name() + '.dbo.' + @CDRFileTable
set @ServerName = @@SERVERNAME

--Select 'Debug: Check the dynamically created Schema and the Server name'
--Select @SchemaName as DatabaseName , @ServerName as ServerName

-- Build the bcp command to import the CDR file into the table

set @SQLStr = 'bcp ' + @SchemaName + ' in "'+@CDRFileName+'" -c -r 0x0a -S '+@ServerName+' -T'

--print @SQLStr

-- Create a temporary table to hold the results of the command run

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCommandOutput') )	
	Drop table #TempCommandOutput

Create table #TempCommandOutput (RecordData varchar(2000))

-- Run the bcp command using the CMD Shell and capture the results

Insert into #TempCommandOutput 
Exec master..xp_cmdshell @SQLStr 

--Select 'Debug: Publish the result of bcp command run and the contents of CDR Table' as status
--Select * from #TempCommandOutput
--Exec('Select * from ' + @CDRFileTable) 

-- Check if there was error in the import of the CDR file into the temp CDR table

if exists ( select 1 from #TempCommandOutput where charindex('ERROR' , RecordData) <> 0)
Begin

    select @ImportError = RecordData from #TempCommandOutput
	where charindex('ERROR' , RecordData) <> 0

	set @ErrorMsgStr = 'SP_BSConverterParseFile : '+ convert(varchar(30) ,getdate() , 120) +
								' : '+'ERROR !!! Exporting data from CDR file ('+ @CDRFileName +') using bcp utility.' + @ImportError

    set @Remarks = 'ERROR !!! Exporting data from CDR file using bcp utility.'
	set @ResultFlag = 1
	Exec SP_LogMessage @ErrorMsgStr , @LogFileName
	GOTO ENDPROCESS

End

-- Add an identity column to the table storing CDR File Records.
-- The identity column will help in ordering the records and also
-- assist in subsetting CDR records from the whole file

Exec('Alter table '+ @CDRFileTable + ' Add RecordID int identity(1,1)')

-- Move the data from the dynamic table to a temporary table for ease
-- of processing and not writing dynamic queries

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCDRFileData') )	
	Drop table #TempCDRFileData

Create table #TempCDRFileData (RecordID int , RecordData varchar(2000))

Exec('insert into #TempCDRFileData select RecordID , RecordData from ' + @CDRFileTable )

--Select 'Debug: Publish the CDR File Data after moving to a temp table' as status
--select * from #TempCDRFileData

--------------------------------------------------------------
-- Find out the total number of records in the file from the 
-- key value pair "Number of CDRs in file:"
--------------------------------------------------------------

-- Remove all spaces from start and end of all the records

update #TempCDRFileData
set RecordData = rtrim(ltrim(RecordData))

--select * from #TempCDRFileData

select @TotalCDRRecordsInFile = substring(rtrim(ltrim(RecordData)) , len('Number of CDRs in file:') + 1 , len(rtrim(ltrim(RecordData))) )
from #TempCDRFileData
where charindex('Number of CDRs in file:', RecordData) <> 0

Select @TotalCDRRecordsInFile as TotalCDRRecordsInFile

-------------------------------------------------------------
-- Loop through all the records in the CDR File table and
-- extract essential information for each record
-------------------------------------------------------------

Declare @CurrentRecord int = 0,
        @NextRecord int = 1,
		@StartRecordID int,
		@EndRecordID int,
		@CurrentKeyFieldsID int,
		@MaxKeyFieldsID int,
		@MinKeyFieldsID int,
		@RecordString varchar(2000),
		@FieldValue varchar(1000),
		@KeyFieldName varchar(500)

-- Get the Min and Max KeyFieldsID from the KeyFields table

select @MinKeyFieldsID = min(KeyFieldsID),
	   @MaxKeyFieldsID = max(KeyFieldsID)
from #TempKeyFieldsData

--select @MinKeyFieldsID as MinKeyFieldsID , @MaxKeyFieldsID as MaxKeyFieldsID

-- Create a temporary running table to store the rows for a particular record number

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCDRFileRecord') )	
	Drop table #TempCDRFileRecord
	
select * into #TempCDRFileRecord
from #TempCDRFileData
where 1 = 2	 

Begin Try

			set @TotalCDRRecordsCalculate = 0

			While ( @CurrentRecord < @TotalCDRRecordsInFile )
			Begin

					-- Subset the rows from the database for a CDR with particular Record number

					Select @StartRecordID  = RecordID
					from #TempCDRFileData
					where RecordData = 'Record ' + convert(varchar(20) , @CurrentRecord)

					if (@NextRecord = @TotalCDRRecordsInFile)
					Begin

							select @EndRecordID = max(RecordID)
							from #TempCDRFileData

					End

					else
					Begin

							Select @EndRecordID  = RecordID - 1
							from #TempCDRFileData
							where RecordData = 'Record ' + convert(varchar(20) , @NextRecord)

					End

					--Select @CurrentRecord as RecordNo , @StartRecordID as StartRow , @EndRecordID as EndRow

					-- Extract and insert the rows from the master table for certain record number
					-- into a temporary running table

					insert into #TempCDRFileRecord
					select * from #TempCDRFileData
					where RecordID between @StartRecordID and @EndRecordID

					--select * from #TempCDRFileRecord

					-- Loop through the list of Key Fields which need to be extracted for 
					-- each CDR Record and build the Record String

					set @RecordString = ''
					set @CurrentKeyFieldsID = @MinKeyFieldsID

					while (@CurrentKeyFieldsID <= @MaxKeyFieldsID)
					Begin

							set @FieldValue = ''

							select @KeyFieldName = FieldName
							from #TempKeyFieldsData
							where KeyFieldsID = @CurrentKeyFieldsID

							select @FieldValue = isnull(substring(RecordData , len(@KeyFieldName) + 2 , len(RecordData)), '')
							from #TempCDRFileRecord
							where substring(RecordData , 1 , len(@KeyFieldName)) = @KeyFieldName

							--Select @KeyFieldName as KeyFieldName , @FieldValue as KeyFieldValue

							set @RecordString = @RecordString + '^|' + @FieldValue

							set @CurrentKeyFieldsID = @CurrentKeyFieldsID + 1

					End

					set @RecordString = substring(@RecordString , 3 , len(@RecordString))

					--select @RecordString as RecordString

					-- Write/Append the CDR Record to the output file

					set @SQLStr = 'echo ' + @RecordString + ' >>' + '"' + @IntermediateFileNameWithFullPath + '"'
					Exec master..xp_cmdshell @SQLStr

					-- Increase the Record number counters to move onto the next CDR Record

					set @CurrentRecord = @CurrentRecord + 1
					set @NextRecord = @NextRecord + 1

					Delete from #TempCDRFileRecord


			End

End Try

Begin Catch

	set @ErrorMsgStr = 'SP_BSConverterParseFile : '+ convert(varchar(30) ,getdate() , 120) +
								' : '+'ERROR !!! Parsing CDR file ('+ @CDRFileName + ') for records.' + ERROR_MESSAGE()

	set @Remarks = 'ERROR !!! Parsing CDR file for records.'
	set @ResultFlag = 1
	Exec SP_LogMessage @ErrorMsgStr , @LogFileName
	GOTO ENDPROCESS

End Catch

set @TotalCDRRecordsCalculate = @CurrentRecord

Select @TotalCDRRecordsCalculate as TotalCDRRecordsCalculate

---------------------------------------------------------------------------
-- Check to ensure that the Total records published in file header and
-- total records calculated in the file are the same
---------------------------------------------------------------------------

if ( @TotalCDRRecordsCalculate <> @TotalCDRRecordsInFile )
Begin

	set @ErrorMsgStr = 'SP_BSConverterParseFile : '+ convert(varchar(30) ,getdate() , 120) +
								' : '+'ERROR !!! Mismatch in the total records as per file header and calculation for CDR file ('+ @CDRFileName +')'
	set @Remarks = 'ERROR !!! Mismatch in the total records as per file header and calculation'
	set @ResultFlag = 1
	Exec SP_LogMessage @ErrorMsgStr , @LogFileName
	GOTO ENDPROCESS

End

---------------------------------------------------------
-- Once complete, rename the intermdiate file to Output
-- file
---------------------------------------------------------

set @cmd = 'Rename ' + '"' + @IntermediateFileNameWithFullPath + '"' + ' ' + '"' + @CDRFileNameWithoutPath + '"'
--print @cmd
Exec master..xp_cmdshell @cmd

set @FileExists = 0

Exec master..xp_fileexist @OutputFileName , @FileExists output 

if ( @FileExists <> 1 )
Begin

 		set @ErrorMsgStr = 'SP_BSConverterParseFile : '+ convert(varchar(30) ,getdate() , 120) +
								' : ' + 'ERROR !!! While renaming Temp CDR file: : ' + @IntermediateFileNameWithFullPath + ' in output folder to output file'
		
		set @Remarks = 'ERROR !!! While renaming Temp CDR file to output file'
				
		Exec SP_LogMessage @ErrorMsgStr , @LogFileName
		set @ResultFlag = 1
		GOTO ENDPROCESS
				     
End

-------------------------------------------------------
-- Delete the input file, once it has been processed
-- successfully
-------------------------------------------------------

set @cmd = 'Del ' + @CDRFileName 
Exec master..xp_cmdshell @cmd

ENDPROCESS:

----------------------------------------------------------------------------------------------------
-- Check to see if there was any errors in the file parsing and based on that update entry in the 
-- statistics table
----------------------------------------------------------------------------------------------------
if (@ResultFlag = 1)
Begin

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

			--------------------------------------------------------
			-- Update the statistics table with file failure status
			--------------------------------------------------------

			update tb_MedConverterStatistics
			set FileStatus = 'Failed',
				TotalRecords = isnull(@TotalCDRRecordsInFile,0),
				TotalOutputRecords = isnull(@TotalCDRRecordsCalculate,0),
			    Remarks = Case When @Remarks is not null Then @Remarks else NULL End,
				TotalProcessTime = datediff(ss, ProcessStartTime , getdate())
			Where CDRFileName = @CDRFileNameWithoutExtension


End

else
Begin

			--------------------------------------------------------
			-- Update the statistics table with file Completed status
			--------------------------------------------------------

			update tb_MedConverterStatistics
			set FileStatus = 'Completed',
				TotalRecords = @TotalCDRRecordsInFile,
				TotalOutputRecords = @TotalCDRRecordsCalculate,
			    Remarks = NULL,
				TotalProcessTime = datediff(ss, ProcessStartTime , getdate())
			Where CDRFileName = @CDRFileNameWithoutExtension

End

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempKeyFieldsData') )	
	Drop table #TempKeyFieldsData

if exists (select 1 from sysobjects where name = @CDRFileTable and xtype = 'U')
	Exec('Drop table ' + @CDRFileTable) 
	
if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCommandOutput') )	
	Drop table #TempCommandOutput	
	
if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCDRFileData') )	
	Drop table #TempCDRFileData	
	
if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCDRFileRecord') )	
	Drop table #TempCDRFileRecord	 
GO
