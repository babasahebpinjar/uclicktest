USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSConverterParseFile]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSConverterParseFile]
(
	@CDRFileName varchar(500),
    @KeyFieldsFile varchar(500),
	@OutputFilePath varchar(500),
	@CDRFileExtension varchar(100),
	@LogFileName varchar(500),
	@ErrorMsgStr varchar(2000) Output,
	@ResultFlag int Output
)
As

-- Example of Input to the procedure

--      @CDRFileName varchar(500) = 'G:\Uclick_Product_Suite\uClickFacilitate\MedCollector\Temp\avh01-5_-_467.20180707_-_1704+0800.CDR',
--      @KeyFieldsFile varchar(500) = 'C:\Uclick_Product_Suite\uClickFacilitate\Format\KeyFields.txt',
--		@OutputFilePath varchar(500) = 'G:\Uclick_Product_Suite\uClickFacilitate\MedConverter\Output\',
--		@CDRFileExtension varchar(100) = '.CDR',
--		@LogFileName varchar(500) = 'F:\Uclick_Product_Suite\uClickFacilitate\Logs\MedConverter.log',


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

-----------------------------------------------------------------------------
-- Added 25th Oct 2018
-- This change has been done to call the script, that adds a sequence no 
-- to each of the records in the file. this is to maintain the same order 
-- as how the records exist in the file before import
------------------------------------------------------------------------------

Begin Try

	Exec SP_BSMedConverterAddSequenceToRecord @CDRFileName, @CDRFileNameWithoutPath,
	                                          @ErrorMsgStr Output , @ResultFlag Output

	if (@ResultFlag = 1)
	Begin

			Exec SP_LogMessage @ErrorMsgStr , @LogFileName
			GOTO ENDPROCESS

	End
						    
End Try

Begin Catch

		set @ErrorMsgStr = 'SP_BSConverterParseFile : '+ convert(varchar(30) ,getdate() , 120) +
									' : '+'ERROR !!! Adding Sequence No to all the records in the CDR File.'

		set @Remarks = 'ERROR !!! Adding Sequence No to all the records in the CDR File.'
		set @ResultFlag = 1
		Exec SP_LogMessage @ErrorMsgStr , @LogFileName
		GOTO ENDPROCESS

End Catch

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

--set @SQLStr = 'bcp ' + @SchemaName + ' in "'+@CDRFileName+'" -c -r 0x0a -S '+@ServerName+' -T'

set @SQLStr = 'bcp ' + @SchemaName + ' in "'+@CDRFileName+'" -c -r \n -S '+@ServerName+' -T'

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

-- Remove all spaces from start and end of all the records

update #TempCDRFileData
set RecordData = rtrim(ltrim(RecordData))

-- Segregate the Record Sequence and Data into sepearet fields

update #TempCDRFileData
set RecordID = convert(int, SUBSTRING(RecordData ,1 , charindex('|' ,RecordData) -1)),
    RecordData = SUBSTRING(RecordData , charindex('|' ,RecordData) + 1 , len(RecordData))

--Select 'Debug: Publish the CDR File Data after moving to a temp table' as status
--select * from #TempCDRFileData order by RecordID

--------------------------------------------------------------
-- Find out the total number of records in the file from the 
-- key value pair "Number of CDRs in file:"
--------------------------------------------------------------

update #TempCDRFileData
set RecordData = rtrim(ltrim(RecordData))

--select * from #TempCDRFileData

select @TotalCDRRecordsInFile = substring(rtrim(ltrim(RecordData)) , len('Number of CDRs in file:') + 1 , len(rtrim(ltrim(RecordData))) )
from #TempCDRFileData
where charindex('Number of CDRs in file:', RecordData) <> 0

--Select @TotalCDRRecordsInFile as TotalCDRRecordsInFile

---------------------------------------------------------------------
-- Format the structure of the CDR file Data table to only contain
-- key value pairs
----------------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCDRFileKeyValueData') )	
	Drop table #TempCDRFileKeyValueData

Create table #TempCDRFileKeyValueData (RecordID int , KeyName varchar(2000) , KeyValue varchar(2000))

insert into #TempCDRFileKeyValueData
select recordID , 
       Case
			When charindex(':' , RecordData) <> 0 Then substring(RecordData , 1 , charindex(':' , RecordData) -1)
			Else RecordData
	   End,
       Case
			When charindex(':' , RecordData) <> 0 Then substring(RecordData , charindex(':' , RecordData) + 1 , len(RecordData))
			Else NULL
	   End
from #TempCDRFileData
where RecordID > 9 -- Hardcode this as the top 9 records are generic file information

--select *
--from #TempCDRFileKeyValueData
--order by RecordID

-- Remove Data for all keys, which are not part of the master
-- key Fields Format File

Delete from #TempCDRFileKeyValueData
where Keyname is NULL

Delete from #TempCDRFileKeyValueData
where KeyName not like 'Record%'
and KeyName not in
(select FieldName from #TempKeyFieldsData)

--Select 'Debug: CDRFile Key Value Data'

--select *
--from #TempCDRFileKeyValueData
--order by RecordID

--------------------------------------------------
-- Construct a dynamic temporary table to hold
-- CDR records for final output file
--------------------------------------------------

Declare @FinalOutputTable varchar(100) = 'TempFinalOutput_'+ replace(replace(replace(convert(varchar(20) , getdate(), 120) , '-', ''), ':' , ''), ' ', ''),
		@VarKeyFieldsID int,
		@VarKeyFieldsName varchar(500)

Begin Try

		-- Loop through the list of Key Fields and build a dynamic table

		if exists (select 1 from sysobjects where name = @FinalOutputTable and xtype = 'U')
			Exec('Drop table ' + @FinalOutputTable) 

		set @SQLStr = 'Create table ' +  @FinalOutputTable + ' ( RecordNo int ,'

		DECLARE db_cur_get_KeyFields CURSOR FOR
		select KeyFieldsID ,FieldName from #TempKeyFieldsData

		OPEN db_cur_get_KeyFields
		FETCH NEXT FROM db_cur_get_KeyFields
		INTO @VarKeyFieldsID , @VarKeyFieldsName 

		While @@FETCH_STATUS = 0
		BEGIN

				set  @SQLStr = @SQLStr + CHAR(10) + 'KeyValue_' + convert(varchar(100) , @VarKeyFieldsID) + ' varchar(2000) ,'

				FETCH NEXT FROM db_cur_get_KeyFields
				INTO @VarKeyFieldsID , @VarKeyFieldsName    		 

		END

		CLOSE db_cur_get_KeyFields
		DEALLOCATE db_cur_get_KeyFields

		set @SQLStr = substring(@SQLStr , 1 , len(@SQLStr)-1) + ')'

		--print @SQLStr

		Exec(@SQLStr)

End Try

Begin Catch

		set @ErrorMsgStr = 'SP_BSConverterParseFile : '+ convert(varchar(30) ,getdate() , 120) +
									' : '+'ERROR !!! Creating Temp table for holding all parsed output records.'

		set @Remarks = 'ERROR !!! Creating Temp table for holding all parsed output records.'
		set @ResultFlag = 1
		Exec SP_LogMessage @ErrorMsgStr , @LogFileName
		GOTO ENDPROCESS

End Catch

--Select 'Debug: Checking definition of dynamically created final output table' as status
--Exec('select * from ' + @FinalOutputTable)

------------------------------------------------------
-- Create a temp table to hold the values of each
-- key for a CDR record. The table will be used as a 
-- Temp storage to hold the key values for each CDR,
-- as we loop through each key defined in the key master
-- file
-------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCDRValuePerKey') )	
	Drop table #TempCDRValuePerKey

Create table #TempCDRValuePerKey (RecordID int , Keyvalue varchar(2000))

--------------------------------------------------------------
-- Create a temp table to hold the record range for each CDR
--------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCDRRecordRange') )	
	Drop table #TempCDRRecordRange

Create table #TempCDRRecordRange (RecordNo int , StartRecordID int , EndRecordID int)


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

-- Loop through the Master CDR table for raw CDR records 
-- and get the range of Record Ids for each CDR record

Begin Try

			While ( @CurrentRecord < @TotalCDRRecordsInFile )
			Begin

					-- Subset the rows from the database for a CDR with particular Record number

					Select @StartRecordID  = RecordID
					from #TempCDRFileKeyValueData
					where KeyName = 'Record ' + convert(varchar(20) , @CurrentRecord)

					if (@NextRecord = @TotalCDRRecordsInFile)
					Begin

							select @EndRecordID = max(RecordID)
							from #TempCDRFileKeyValueData

					End

					else
					Begin

							Select @EndRecordID  = RecordID - 1
							from #TempCDRFileKeyValueData
							where KeyName = 'Record ' + convert(varchar(20) , @NextRecord)

					End

					insert into #TempCDRRecordRange 
					(RecordNo , StartRecordID , EndRecordID)
					values (@CurrentRecord , @StartRecordID , @EndRecordID)

					set @CurrentRecord = @CurrentRecord + 1
					set @NextRecord = @NextRecord + 1

			End

End Try

Begin Catch

		set @ErrorMsgStr = 'SP_BSConverterParseFile : '+ convert(varchar(30) ,getdate() , 120) +
									' : '+'ERROR !!! Finding record range for each CDR record'

		set @Remarks = 'ERROR !!! Finding record range for each CDR record'
		set @ResultFlag = 1
		Exec SP_LogMessage @ErrorMsgStr , @LogFileName
		GOTO ENDPROCESS

End Catch

--Select 'Debug: Checking record range fro each CDR Record' as Status
--Select * from #TempCDRRecordRange order by RecordNo
 
-- Get the Min and Max KeyFieldsID from the KeyFields table

select @MinKeyFieldsID = min(KeyFieldsID),
	   @MaxKeyFieldsID = max(KeyFieldsID)
from #TempKeyFieldsData

--select @MinKeyFieldsID as MinKeyFieldsID , @MaxKeyFieldsID as MaxKeyFieldsID

Begin Try

			-- Loop through the list of Key Fields which need to be extracted for 
			-- each CDR Record 

			set @CurrentKeyFieldsID = @MinKeyFieldsID

			while (@CurrentKeyFieldsID <= @MaxKeyFieldsID)
			Begin

			        select @KeyFieldName = FieldName
					from #TempKeyFieldsData
					where KeyFieldsID = @CurrentKeyFieldsID

			        set @SQLStr = 'Insert into  #TempCDRValuePerKey (RecordID , KeyValue)' + char(10)+
					              'select RecordID , KeyValue from  #TempCDRFileKeyValueData '+ char(10)+
								  'where keyname = '''  + @KeyFieldName + ''''

					--print @SQLStr

					Exec(@SQLStr)

					--select * from #TempCDRValuePerKey order by RecordID

					-- Populate the value in the final output table for each record
					-- no using the record Id range

					if ( @CurrentKeyFieldsID = 1) -- First Key value being processed
					Begin

							set @SQLStr = 'insert into ' + @FinalOutputTable + '(RecordNo , KeyValue_' + convert(varchar(100) ,@CurrentKeyFieldsID) + ')' + char(10)+ 
										  'select tbl1.RecordNo , tbl2.KeyValue ' + char(10)+
										  ' from #TempCDRRecordRange tbl1' + char(10) +
										  ' left join #TempCDRValuePerKey tbl2 on tbl2.RecordID between tbl1.StartRecordID and tbl1.EndRecordID'

							--print @SQLStr
									     
							Exec(@SQLStr)

							--Select 'DEBUG: Publishing the Final Output table after the first insert of data'
							--select * from #TempCDRValuePerKey order by recordID desc
							--Exec('Select * from ' + @FinalOutputTable + ' order by RecordNo')

					End

					else
					Begin

							set @SQLStr = 'update tbl3 '+ char(10)+
										  ' set tbl3.KeyValue_' + convert(varchar(100) ,@CurrentKeyFieldsID) +' = tbl2.KeyValue' + char(10)+
										  ' from #TempCDRRecordRange tbl1' + char(10) +
										  ' left join #TempCDRValuePerKey tbl2 on tbl2.RecordID between tbl1.StartRecordID and tbl1.EndRecordID' + char(10) +
										  ' inner join ' + @FinalOutputTable + ' tbl3 on tbl1.RecordNo = tbl3.RecordNo'

							--print @SQLStr
									     
							Exec(@SQLStr)

					End

					delete from #TempCDRValuePerKey

					--Exec('Select * from ' + @FinalOutputTable + ' order by RecordNo')

					set @CurrentKeyFieldsID = @CurrentKeyFieldsID + 1

			End


End Try

Begin Catch

	set @ErrorMsgStr = 'SP_BSConverterParseFile : '+ convert(varchar(30) ,getdate() , 120) +
								' : '+'ERROR !!! Extracting Key Field Values for all CDR records.' + ERROR_MESSAGE()

	set @Remarks = 'ERROR !!! Extracting Key Field Values for all CDR records.'
	set @ResultFlag = 1
	Exec SP_LogMessage @ErrorMsgStr , @LogFileName
	GOTO ENDPROCESS

End Catch

----Exec('Select * from ' + @FinalOutputTable + ' order by RecordNo')

-------------------------------------------------------------
-- Find the total number of records in the final output file
-------------------------------------------------------------

Declare @vParams nvarchar(100),
        @TempSql nvarchar(2000)

Set @vParams = '@vCnt int OUTPUT'

Select @TempSql = 'Select @vCnt = count(*) From ' + @FinalOutputTable

Exec sp_executesql @TempSql,@vParams,@vCnt=@TotalCDRRecordsCalculate OUTPUT

--Select @TotalCDRRecordsCalculate as TotalCDRRecordsCalculate

---------------------------------------------------------------------------
-- Check to ensure that the Total records published in file header and
-- total records calculated in the file are the same
---------------------------------------------------------------------------

if ( isnull(@TotalCDRRecordsCalculate,0) <> @TotalCDRRecordsInFile )
Begin

	set @ErrorMsgStr = 'SP_BSConverterParseFile : '+ convert(varchar(30) ,getdate() , 120) +
								' : '+'ERROR !!! Mismatch in the total records as per file header and calculation for CDR file ('+ @CDRFileName +')'
	set @Remarks = 'ERROR !!! Mismatch in the total records as per file header and calculation'
	set @ResultFlag = 1
	Exec SP_LogMessage @ErrorMsgStr , @LogFileName
	GOTO ENDPROCESS

End

---------------------------------------------------------
-- Publish the Final output table to intermediate file
---------------------------------------------------------

set @SchemaName = db_name() + '.dbo.' + @FinalOutputTable
set @ServerName = @@SERVERNAME

--Select 'Debug: Check the dynamically created Schema and the Server name'
--Select @SchemaName as DatabaseName , @ServerName as ServerName

set @SQLStr = 'bcp "select * from '+ @SchemaName +' order by RecordNo" queryout ' + '"'+@IntermediateFileNameWithFullPath + '"' + ' -c -t "|" -r"\n" -T -S '+ @ServerName

Exec master..xp_cmdshell @SQLStr

-- Check to see if the intermediate file has been created or not

set @FileExists = 0

Exec master..xp_fileexist @IntermediateFileNameWithFullPath , @FileExists output  

if ( @FileExists <> 1 )
Begin

 		set @ErrorMsgStr = 'SP_BSConverterParseFile : '+ convert(varchar(30) ,getdate() , 120) +
								' : ' + 'ERROR !!! Intermediate output CDR file (' + @IntermediateFileNameWithFullPath + ') not created'
		
		set @Remarks = 'ERROR !!! Intermediate output CDR file not created'
				
		Exec SP_LogMessage @ErrorMsgStr , @LogFileName
		set @ResultFlag = 1
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

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCDRFileKeyValueData') )	
	Drop table #TempCDRFileKeyValueData

if exists (select 1 from sysobjects where name = @FinalOutputTable and xtype = 'U')
	Exec('Drop table ' + @FinalOutputTable) 

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCDRValuePerKey') )	
	Drop table #TempCDRValuePerKey

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCDRRecordRange') )	
	Drop table #TempCDRRecordRange
GO
