USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMedCorrelateStore]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSMedCorrelateStore]
(
    @AccessScopeID int,
    @SourceFilePath varchar(1000),
	@CDRFileName varchar(1000),
	@AbsoluteLogFilePath varchar(1000),
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @RejectFileName varchar(1000),
        @Command varchar(1000),
		@RowTerminator varchar(100),
		@FieldTerminator varchar(100),
		@SQLStr varchar(2000),
		@result int,
		@ProcessErrorFileName varchar(1000),
		@FileExists int

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempCommandoutput') )
	Drop table #tempCommandoutput

create table #tempCommandoutput (CommandOutput varchar(1000) )

----------------------------------------------------------------
-- Build the complete name of the CDR file with Source Path
----------------------------------------------------------------

Declare @AbsoluteCDRFileName varchar(1000)

set @AbsoluteCDRFileName = 
		Case
			When right(@SourceFilePath, 1 ) <> '\' then @SourceFilePath + '\' + @CDRFileName
			Else @SourceFilePath + @CDRFileName
		End

-------------------------------------------------------------------
-- Get the following parameters essential for processing the file
-------------------------------------------------------------------

Declare @RejectFilePath varchar(1000),
        @InputFileExtension varchar(1000),
		@CDRFileNameWithoutExtension varchar(1000)

Select @RejectFilePath = ConfigValue
from Tb_Config
where ConfigName = 'RejectFilePath'
and AccessScopeID = @AccessScopeID

if ( right(@RejectFilePath,1) <> '\' )
	set @RejectFilePath = @RejectFilePath + '\'

Select @InputFileExtension = ConfigValue
from Tb_Config
where ConfigName = 'InputFileExtension'
and AccessScopeID = @AccessScopeID

set @CDRFileNameWithoutExtension = substring(@CDRFileName , 1 , charindex(@InputFileExtension , @CDRFileName ) - 1 ) 

------------------------------------------------------
-- Get the config value for Retain Original File Flag
------------------------------------------------------

Declare @RetainOriginalFile int
       
Select @RetainOriginalFile = ConfigValue
from Tb_Config
where ConfigName = 'RetainOriginalFile'
and AccessScopeID = @AccessScopeID

-----------------------------------------------------------------
-- Check if there already exists a record for the file in the
-- statistics table
-----------------------------------------------------------------

if exists ( select 1 from tb_MedCorrelateStatistics where CDRFilename = @CDRFileNameWithoutExtension and FileStatus = 'Upload Complete' )
Begin

     set @RejectFileName = @RejectFilePath + @CDRFileNameWithoutExtension + '.AlreadyProcessed'

     Select @Command = 'move ' +'"'+@AbsoluteCDRFileName+'"'+ ' '+ '"'+@RejectFileName+'"'
      --print @Command

     Insert into #tempCommandoutput
     Exec master..xp_cmdshell @Command

     If exists ( select 1 from #tempCommandoutput where ltrim(CommandOutput) = '1 file(s) moved.')
     Begin
           truncate table #tempCommandoutput
           set @ResultFlag = 0
		   GOTO ENDPROCESS
     End

     Else
     Begin
           truncate table #tempCommandoutput
	       set @ErrorDescription = 'SP_BSMedCorrelateStore : '+ convert(varchar(30) ,getdate() , 120) +
	                        ' : ' + ' ERROR !!!! Moving CDR file to Reject folder'

           Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

		   set @ResultFlag = 1

		   GOTO ENDPROCESS

     End

End

------------------------------------------------------------
-- Delete the previous entry and create a new entry for the
-- file in  the schema
------------------------------------------------------------

-------------------------------------------------------
-- Delete records from the subsidiary tables as well
-------------------------------------------------------

Delete tbl1
from tb_ITypeRecords tbl1
inner join tb_MedCorrelateStatistics tbl2 on tbl1.CDRFileID = tbl2.CDRFileID
where tbl2.CDRFilename = @CDRFileNameWithoutExtension

Delete tbl1
from tb_OTypeRecords tbl1
inner join tb_MedCorrelateStatistics tbl2 on tbl1.CDRFileID = tbl2.CDRFileID
where tbl2.CDRFilename = @CDRFileNameWithoutExtension

Delete tbl1
from tb_ZTypeRecords tbl1
inner join tb_MedCorrelateStatistics tbl2 on tbl1.CDRFileID = tbl2.CDRFileID
where tbl2.CDRFilename = @CDRFileNameWithoutExtension

Delete from tb_MedCorrelateStatistics 
where CDRFilename = @CDRFileNameWithoutExtension

-------------------------------------------------------------------
-- insert new entry into the statistics table for the CDr file
-------------------------------------------------------------------

insert into tb_MedCorrelateStatistics 
(
	CDRFileName,
	TotalRecords,
	I_TypeRecords,
	O_TypeRecords,
	Z_TypeRecords,
	DiscardRecords,
	FileStatus,
	Remarks
)
Values
(
	@CDRFileNameWithoutExtension,
	0,
	0,
	0,
	0,
	0,
	'Upload InProgress',
	NULL
)

------------------------------------------------------------
-- Get the CDR File ID from the database table for use
-- while processing
------------------------------------------------------------

Declare @CDRFileID int

select @CDRFileID = CDRFileID
from tb_MedCorrelateStatistics
where CDRFilename = @CDRFileNameWithoutExtension
and FileStatus = 'Upload InProgress'

---------------------------------------------------------------------------
-- Move the status of the CDR file to Intermediary Extension so that no
-- other process picks up the file
---------------------------------------------------------------------------

Declare @IntermediateFileExtension varchar(100)

Select @IntermediateFileExtension =  ConfigValue
from Tb_Config
where ConfigName = 'IntermediateFileExtension'
and AccessScopeID = @AccessScopeID

set @Command = 'rename ' + '"'+@AbsoluteCDRFileName+'"' + ' '+ '"'+ @CDRFileNameWithoutExtension + @IntermediateFileExtension +'"'
--print @Command 

exec @result = master..xp_cmdshell @Command
if @result <> 0
Begin	
			set @ErrorDescription = 'SP_BSMedCorrelateStore : '+ convert(varchar(30) ,getdate() , 120) +
			                        ' : ' + ' ERROR !!! Failed to change the extension of Original CDR file : ' + @CDRFileName +' to : ' +  @IntermediateFileExtension + ' befor starting processing'

			Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

            -----------------------------------------------------------------------
            -- Update the status of file to 'ERROR' and add description for Error
            -----------------------------------------------------------------------
                     
            update tb_MedCorrelateStatistics 
            set FileStatus = 'Upload Error',
            Remarks = 'Error Failed to change the extension of Original CDR file to intermediate extension, before starting processing'
            where cdrfilename = @CDRFileNameWithoutExtension 
            and FileStatus = 'Upload InProgress'

            set @ResultFlag = 1

			GOTO ENDPROCESS

End

------------------------------------------------------------------------
-- If the renaming of the file to intermediary extension was successful, 
-- then replace the name of the AbsoluteCDRFileName with the intermediary
-- file name
-------------------------------------------------------------------------

set @AbsoluteCDRFileName = Replace(@AbsoluteCDRFileName , @InputFileExtension , @IntermediateFileExtension) 

-------------------------------------------------------------
-- Upload the CDR File into a temporary table and process
-- the records
-------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempCDRFileData') )
	Drop table #tempCDRFileData

create table #tempCDRFileData ( CDRFileRecord varchar(max))


Begin Try

set @RowTerminator = '\n'
set @FieldTerminator = ',' 

Select	@SQLStr = 'Bulk Insert  #tempCDRFileData '+ ' From ' 
		          + '''' + @AbsoluteCDRFileName +'''' + ' WITH (
		          FIELDTERMINATOR  = ''' + @FieldTerminator + ''','+
                  'ROWTERMINATOR    = ''' + @RowTerminator + ''''+')'

--print @SQLStr
Exec (@SQLStr)

End Try

Begin Catch

    set @ErrorDescription = 'ERROR: Importing CDR File :' + @CDRFileNameWithoutExtension + ' into Database.' + ERROR_MESSAGE()
  
    set @ErrorDescription = 'SP_BSMedCorrelateStore : '+ convert(varchar(30) ,getdate() , 120) +
	                        ' : ' + @ErrorDescription
    Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

   ----------------------------------------------------------------------
   -- Update the status of file to 'ERROR' and add description for Error
   ----------------------------------------------------------------------

   update tb_MedCorrelateStatistics
   set FileStatus = 'Upload Error',
       Remarks = 'Error Importing CDR File into Database. Check File Format'
   where cdrfilename = @CDRFileNameWithoutExtension 
   and FileStatus = 'Upload InProgress'

   set @ResultFlag = 1

   GOTO ENDPROCESS

End Catch

------------------------------------------------------------------
-- Add an identity field to assign a unique ID to each CDR Record
------------------------------------------------------------------

Alter table #tempCDRFileData Add BERID int identity(1,1)

------------------------------------------------------
-- Now we need to create the Correlation key for each
-- record depending on the configuration parameters
------------------------------------------------------

Declare @I_RecordCorrelationKey_1 int,
        @I_RecordCorrelationKey_2 int,
		@O_RecordCorrelationKey_1 int,
		@O_RecordCorrelationKey_2 int,
		@Z_RecordCorrelationKey_1 int,
		@Z_RecordCorrelationKey_2 int

select @I_RecordCorrelationKey_1 = convert(int ,ConfigValue)
from tb_Config
where AccessScopeID = @AccessScopeID
and Configname = 'I_RecordCorrelationKey_1'

select @I_RecordCorrelationKey_2 = convert(int ,ConfigValue)
from tb_Config
where AccessScopeID = @AccessScopeID
and Configname = 'I_RecordCorrelationKey_2'

select @O_RecordCorrelationKey_1 = convert(int ,ConfigValue)
from tb_Config
where AccessScopeID = @AccessScopeID
and Configname = 'O_RecordCorrelationKey_1'

select @O_RecordCorrelationKey_2 = convert(int ,ConfigValue)
from tb_Config
where AccessScopeID = @AccessScopeID
and Configname = 'O_RecordCorrelationKey_2'

select @Z_RecordCorrelationKey_1 = convert(int ,ConfigValue)
from tb_Config
where AccessScopeID = @AccessScopeID
and Configname = 'Z_RecordCorrelationKey_1'

select @Z_RecordCorrelationKey_2 = convert(int ,ConfigValue)
from tb_Config
where AccessScopeID = @AccessScopeID
and Configname = 'Z_RecordCorrelationKey_2'

------------------------------------------------------------------------
-- Check to ensure that none of these configuration parameters are NULL
------------------------------------------------------------------------

if ( (@I_RecordCorrelationKey_1 is NULL) or (@I_RecordCorrelationKey_2 is NULL) )
Begin

		set @ErrorDescription = 'ERROR !!! Correlation parameters I_RecordCorrelationKey_1 or I_RecordCorrelationKey_2 for I record are not configured'
		set @ErrorDescription = 'SP_BSMedCorrelateStore : '+ convert(varchar(30) ,getdate() , 120) + ' : ' + @ErrorDescription

		Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

	   ----------------------------------------------------------------------
	   -- Update the status of file to 'ERROR' and add description for Error
	   ----------------------------------------------------------------------

	   update tb_MedCorrelateStatistics
	   set FileStatus = 'Upload Error',
		   Remarks = 'Correlation parameters I_RecordCorrelationKey_1 or I_RecordCorrelationKey_2 for I record are not configured'
	   where cdrfilename = @CDRFileNameWithoutExtension 
	   and FileStatus = 'Upload InProgress'

		set @ResultFlag = 1

		GOTO ENDPROCESS

End


if ( (@O_RecordCorrelationKey_1 is NULL) or (@O_RecordCorrelationKey_2 is NULL) )
Begin

		set @ErrorDescription = 'ERROR !!! Correlation parameters O_RecordCorrelationKey_1 or O_RecordCorrelationKey_2 for O record are not configured'
		set @ErrorDescription = 'SP_BSMedCorrelateStore : '+ convert(varchar(30) ,getdate() , 120) + ' : ' + @ErrorDescription

		Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

	   ----------------------------------------------------------------------
	   -- Update the status of file to 'ERROR' and add description for Error
	   ----------------------------------------------------------------------

	   update tb_MedCorrelateStatistics
	   set FileStatus = 'Upload Error',
		   Remarks = 'Correlation parameters O_RecordCorrelationKey_1 or O_RecordCorrelationKey_2 for O record are not configured'
	   where cdrfilename = @CDRFileNameWithoutExtension 
	   and FileStatus = 'Upload InProgress'

		set @ResultFlag = 1

		GOTO ENDPROCESS

End


if ( (@Z_RecordCorrelationKey_1 is NULL) or (@Z_RecordCorrelationKey_2 is NULL) )
Begin

		set @ErrorDescription = 'ERROR !!! Correlation parameters Z_RecordCorrelationKey_1 or Z_RecordCorrelationKey_2 for Z record are not configured'
		set @ErrorDescription = 'SP_BSMedCorrelateStore : '+ convert(varchar(30) ,getdate() , 120) + ' : ' + @ErrorDescription

		Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

	   ----------------------------------------------------------------------
	   -- Update the status of file to 'ERROR' and add description for Error
	   ----------------------------------------------------------------------

	   update tb_MedCorrelateStatistics
	   set FileStatus = 'Upload Error',
		   Remarks = 'Correlation parameters Z_RecordCorrelationKey_1 or Z_RecordCorrelationKey_2 for Z record are not configured'
	   where cdrfilename = @CDRFileNameWithoutExtension 
	   and FileStatus = 'Upload InProgress'

		set @ResultFlag = 1

		GOTO ENDPROCESS

End

----------------------------
-- Start For Debug Purpose
----------------------------

--Select *
--from #tempCDRFileData

----------------------------
-- End For Debug Purpose
----------------------------

-------------------------------------------------------------
-- Segregate the records depending on their Record Type,
-- and store the following information about each record
-- Correlation ID
-- Correlation Date
-- Record Type
-- Record Data
-------------------------------------------------------------

------------------------------------------------
-- Create temporary tables to store records
------------------------------------------------

Begin Try

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_IOZTypeRecords') )
	Drop table #temp_IOZTypeRecords

create table #temp_IOZTypeRecords
(
    BERID int,
	RecordElement varchar(10),
	CorrelationID varchar(200),
	CorrelationDate DateTime,
	RecordType int,
	RecordData varchar(3000)
)

insert into #temp_IOZTypeRecords
(
    BERID,
	RecordElement,
	CorrelationID,
	CorrelationDate,
	RecordType,
	RecordData
)

Select 
    BERID,
    substring(CDRFileRecord , 1,1),
    Case
			When substring(CDRFileRecord , 1,1) = 'I' Then dbo.FN_BSMedGetFieldValue( CDRFileRecord, @I_RecordCorrelationKey_1 , ',')
			When substring(CDRFileRecord , 1,1) = 'O' Then dbo.FN_BSMedGetFieldValue( CDRFileRecord, @O_RecordCorrelationKey_1 , ',')
			When substring(CDRFileRecord , 1,1) = 'Z' Then dbo.FN_BSMedGetFieldValue( CDRFileRecord, @Z_RecordCorrelationKey_1 , ',')
	End,
    Case
			When substring(CDRFileRecord , 1,1) = 'I' Then dbo.FN_BSMedCreateDateTimeValue(dbo.FN_BSMedGetFieldValue( CDRFileRecord, @I_RecordCorrelationKey_2 , ','))
			When substring(CDRFileRecord , 1,1) = 'O' Then dbo.FN_BSMedCreateDateTimeValue(dbo.FN_BSMedGetFieldValue( CDRFileRecord, @O_RecordCorrelationKey_2 , ','))
			When substring(CDRFileRecord , 1,1) = 'Z' Then dbo.FN_BSMedCreateDateTimeValue(dbo.FN_BSMedGetFieldValue( CDRFileRecord, @Z_RecordCorrelationKey_2 , ','))
	End,
	dbo.FN_BSMedGetFieldValue( CDRFileRecord, 3 , ','),
	substring(CDRFileRecord ,len(dbo.FN_BSMedGetFieldValue( CDRFileRecord, 1 , ',')) + len(dbo.FN_BSMedGetFieldValue( CDRFileRecord, 2 , ',')) + len(dbo.FN_BSMedGetFieldValue( CDRFileRecord, 3 , ',')) + 4  , len(CDRFileRecord))
from #tempCDRFileData

End Try

Begin Catch

    set @ErrorDescription = ' ERROR !!! When Extracting Correlation keys and storing records in Temp Table for CDR File' + @CDRFileNameWithoutExtension +'.' + ERROR_MESSAGE()
    set @ErrorDescription = 'SP_BSMedCorrelateStore : '+ convert(varchar(30) ,getdate() , 120) + ' : ' + @ErrorDescription

    Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

   ----------------------------------------------------------------------
   -- Update the status of file to 'ERROR' and add description for Error
   ----------------------------------------------------------------------

   update tb_MedCorrelateStatistics
   set FileStatus = 'Upload Error',
       Remarks = 'When Extracting Correlation keys and storing records in Temp Table'
   where cdrfilename = @CDRFileNameWithoutExtension 
   and FileStatus = 'Upload InProgress'

	set @ResultFlag = 1

	GOTO ENDPROCESS

End Catch

---------------------------------------------------------------------------
-- Get the count of each type of records and update the statistics tables
---------------------------------------------------------------------------

Declare @Total_ITypeRecords int,
        @Total_OTypeRecords int,
		@Total_ZTypeRecords int,
		@TotalCount int,
		@TotalDiscardRecords int

select @Total_ITypeRecords = count(*)
from #temp_IOZTypeRecords
where RecordElement = 'I'
and RecordType in ('0' , '3')

select @Total_ZTypeRecords = count(*)
from #temp_IOZTypeRecords
where RecordElement = 'Z'
and RecordType in ('0' , '3')

select @Total_OTypeRecords = count(*)
from #temp_IOZTypeRecords
where RecordElement = 'O'
and RecordType in ('0' , '3')

select @TotalCount = count(*)
from #tempCDRFileData

select @TotalDiscardRecords = count(*)
from #temp_IOZTypeRecords
where RecordType not in ('0' , '3')

------------------------------------------------------------
-- Update the statistics in the DB Schema for the CDR file
------------------------------------------------------------

update tb_MedCorrelateStatistics
set I_TypeRecords = @Total_ITypeRecords,
    Z_TypeRecords = @Total_ZTypeRecords,
	O_TypeRecords = @Total_OTypeRecords,
	TotalRecords = @TotalCount,
	DiscardRecords = @TotalDiscardRecords
where CDRFileName = @CDRFileNameWithoutExtension
and fileStatus = 'Upload InProgress'

-----------------------------------------------------------------------------------
-- Upload the records from the temp table into their respective RECORD TYPE tables
-----------------------------------------------------------------------------------

Begin Try

    ----------------------
	-- I_Type Records
	----------------------

	insert into tb_ITypeRecords
	( CDRFileID , BERID ,CorrelationID , CorrelationDate ,RecordType, RecData , ProcessDate )
	Select 	@CDRFileID,
	        BERID,
			CorrelationID,
			CorrelationDate,
			RecordType,
			RecordData,
			Getdate()
    from #temp_IOZTypeRecords
	where RecordElement = 'I'
	and RecordType in ('0' , '3')

    ----------------------
	-- Z_Type Records
	----------------------

	insert into tb_ZTypeRecords
	( CDRFileID , BERID ,CorrelationID , CorrelationDate, RecordType, RecData , ProcessDate )
	Select 	@CDRFileID,
			BERID,
			CorrelationID,
			CorrelationDate,
			RecordType,
			RecordData,
			Getdate()
    from #temp_IOZTypeRecords
	where RecordElement = 'Z'
	and RecordType in ('0' , '3')

   ----------------------
	-- O_Type Records
	----------------------

	insert into tb_OTypeRecords
	( CDRFileID , BERID ,CorrelationID , CorrelationDate , RecordType, RecData , ProcessDate , UsedInCorrelationFlag )
	Select 	@CDRFileID,
			BERID,
			CorrelationID,
			CorrelationDate,
			RecordType,
			RecordData,
			Getdate(),
			0
    from #temp_IOZTypeRecords
	where RecordElement = 'O'
	and RecordType in ('0' , '3')


End Try

Begin Catch

    set @ErrorDescription = ' ERROR !!! Storing records in the Record Type schema for CDR File ' + @CDRFileNameWithoutExtension +'.' + ERROR_MESSAGE()
    set @ErrorDescription = 'SP_BSMedCorrelateStore : '+ convert(varchar(30) ,getdate() , 120) + ' : ' + @ErrorDescription

    Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

   ----------------------------------------------------------------------
   -- Update the status of file to 'ERROR' and add description for Error
   ----------------------------------------------------------------------

   update tb_MedCorrelateStatistics
   set FileStatus = 'Upload Error',
       Remarks = 'Error Storing records in the Record Type schema'
   where cdrfilename = @CDRFileNameWithoutExtension 
   and FileStatus = 'Upload InProgress'

	set @ResultFlag = 1

	GOTO ENDPROCESS

End Catch

------------------------------------------------------------------
-- Move all the Discared records into the Discard file and output
------------------------------------------------------------------

if ( ISNULL(@TotalDiscardRecords,0) > 0)
Begin

		Declare @DiscardFileName varchar(1000),
		        @DiscardFolderPath varchar(1000),
				@QualifiedTableName varchar(500),
				@TempTableName varchar(500),
				@bcpCommand varchar(2000)



		select @DiscardFolderPath =  ConfigValue
		from Tb_Config
		where ConfigName = 'DiscardFolderPath'
		and AccessScopeID = @AccessScopeID

		set @DiscardFileName = 
		       Case
					When right(@DiscardFolderPath , 1) <> '\' then @DiscardFolderPath + '\' + @CDRFileNameWithoutExtension + '.Discard'
					Else @DiscardFolderPath + @CDRFileNameWithoutExtension + '.Discard'
			   End 

		--------------------------------------------------------------
		-- Remove any previous instance of the DISCARD file if exists
		--------------------------------------------------------------

		set @FileExists = 0

        Exec master..xp_fileexist @DiscardFileName , @FileExists output 

		If (@FileExists = 1)
		Begin

				set @Command = 'del ' + '"'+@DiscardFileName +'"'
				--print @Command 

				Exec master..xp_cmdshell @Command

		End

  
		set @QualifiedTableName = 'temp_IOZTypeRecords' + '_' + replace(replace(replace(convert(varchar(30), getdate(), 120) , '-' , ''), ':' , ''), ' ', '') + '_' + convert(varchar(30) ,convert(int ,rand() * 1000))

		Exec ('Select * into ' + @QualifiedTableName + ' from #temp_IOZTypeRecords where RecordType not in (''0'' , ''3'')')

		set @TempTableName = @QualifiedTableName

		set @QualifiedTableName = db_name() + '.dbo.' + @QualifiedTableName

		----------------------------------
		-- For Debugging purpose Start
		----------------------------------
		--Exec('Select * from ' + @QualifiedTableName )
		----------------------------------
		-- For Debugging purpose End
		----------------------------------

		SET @bcpCommand = 'bcp "SELECT *  from ' +
                           @QualifiedTableName +'" queryout ' + '"'+ltrim(rtrim(@DiscardFileName)) + '"' +' -c -t "," -r"\n" -T -S '+ @@servername

		----------------------------------
		-- For Debugging purpose Start
		----------------------------------
		--select @@servername , @bcpCommand as 'BCPCommand'
		----------------------------------
		-- For Debugging purpose End
		----------------------------------

		exec master..xp_cmdshell @bcpCommand

         ------------------------------------------------
         -- Check if the extract has been created or not 
         ------------------------------------------------

        set @FileExists = 0

		Exec master..xp_fileexist @DiscardFileName , @FileExists output  

		if ( @FileExists <> 1 )
		Begin

			set @ErrorDescription = ' ERROR !!! Failed to create discard output for CDR file : ' + @CDRFileNameWithoutExtension

			set @ErrorDescription = 'SP_BSMedCorrelateStore : '+ convert(varchar(30) ,getdate() , 120) +
			                         ' : ' + @ErrorDescription

			Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

             -----------------------------------------------------------------------
             -- Update the status of file to 'ERROR' and add description for Error
             -----------------------------------------------------------------------
                     
             update tb_MedCorrelateStatistics 
             set FileStatus = 'Upload Error',
             Remarks = 'ERROR Failed to create discard output for CDR file'
             where cdrfilename = @CDRFileNameWithoutExtension 
             and FileStatus = 'Upload InProgress'

			set @ResultFlag = 1

			GOTO ENDPROCESS

		End


End

-------------------------------------------------------------------
-- Check the Retain Original File Flag and depending on the value
-- decide whether to purge or hold the original file
-------------------------------------------------------------------

If ( @RetainOriginalFile = 1 )
Begin

    set @Command = 'rename ' + '"'+ @AbsoluteCDRFileName +'"' + ' '+ '"'+ @CDRFileNameWithoutExtension + '.processed' +'"'
	--print @Command 

	exec @result = master..xp_cmdshell @Command
	if @result <> 0
	Begin	

			 set @ErrorDescription = 'SP_BSMedCorrelateStore : '+ convert(varchar(30) ,getdate() , 120) +
			                         ' : ' + ' ERROR !!! Failed to change the extension of Original CDR file : ' + @CDRFileNameWithoutExtension +' to .PROCESSED, after finishing processing'

			Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

             -----------------------------------------------------------------------
             -- Update the status of file to 'ERROR' and add description for Error
             -----------------------------------------------------------------------
                     
             update tb_MedCorrelateStatistics 
             set FileStatus = 'Upload Error',
             Remarks = 'Error Failed to change the extension of Original CDR file to .PROCESSED, after finishing processing'
             where cdrfilename = @CDRFileNameWithoutExtension 
             and FileStatus = 'Upload InProgress'

             set @ResultFlag = 1

			 GOTO ENDPROCESS

	End

End

Else
Begin 

    set @Command = 'del ' + '"'+replace(@AbsoluteCDRFileName ,@InputFileExtension , @IntermediateFileExtension)+'"'
	--print @Command 

        Insert into #tempCommandoutput
        Exec master..xp_cmdshell @Command

        If not exists ( select 1 from #tempCommandoutput where CommandOutput is not NULL )
        Begin

             truncate table #tempCommandoutput
             
        End

       Else
       Begin

             truncate table #tempCommandoutput

			 set @ErrorDescription = 'SP_BSMedCorrelateStore : '+ convert(varchar(30) ,getdate() , 120) +
			                         ' : ' + ' ERROR !!! Failed to delete the Original CDR file : ' + @CDRFileNameWithoutExtension + ' at the end of processing'

			 Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

             -----------------------------------------------------------------------
             -- Update the status of file to 'ERROR' and add description for Error
             -----------------------------------------------------------------------

             update tb_MedCorrelateStatistics 
             set FileStatus = 'Upload Error',
             Remarks = 'Error Failed to delete the Original CDR file at the end of processing'
             where cdrfilename = @CDRFileNameWithoutExtension 
             and FileStatus = 'Upload InProgress'

             set @ResultFlag = 1

			 GOTO ENDPROCESS

       End


End

--------------------------------------------------------------------
-- Change the status of the file post processing to UPLOAD COMPLETE
--------------------------------------------------------------------

update tb_MedCorrelateStatistics 
set FileStatus = 'Upload Completed'
where cdrfilename = @CDRFileNameWithoutExtension 
and FileStatus = 'Upload InProgress'

ENDPROCESS:

------------------------------------------------------------------
-- Move the CDR File to PROCESS ERROR state in case of Errors
------------------------------------------------------------------

if ( @ResultFlag = 1 )
Begin

     set @ProcessErrorFileName = @CDRFileName + '.ProcessError'
	 Select @Command = 'rename ' +'"'+ @AbsoluteCDRFileName +'"'+ ' '+ '"'+@ProcessErrorFileName+'"'
      --print @Command
     Exec master..xp_cmdshell @Command

	 -------------------------------------------------------------
	 -- Remove data from all subsidiary tables as part of rollback
	 --------------------------------------------------------------

	delete from tb_ITypeRecords where CDRFileID = @CDRFileID
	delete from tb_OTypeRecords where CDRFileID = @CDRFileID
	delete from tb_ZTypeRecords where CDRFileID = @CDRFileID


End

----------------------------------------------------------
-- Delete the temporary tables post processing of CDR file
----------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempCommandoutput') )
	Drop table #tempCommandoutput

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempCDRFileData') )
	Drop table #tempCDRFileData

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#temp_IOZTypeRecords') )
	Drop table #temp_IOZTypeRecords

if exists (select 1 from sysobjects where xtype = 'U' and name = @TempTableName )
	Exec('Drop table ' + @TempTableName )


GO
