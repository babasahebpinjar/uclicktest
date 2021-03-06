USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMedArchiveRefresh_Old]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSMedArchiveRefresh_Old]
(
	 @LogFilePath varchar(1000),
     @ErrorDescription varchar(2000) Output,
	 @ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0 

------------------------------------------------------------
-- Check to ensure that the log file path is valid
------------------------------------------------------------

Declare @Command varchar(2000)

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempCommandoutput') )
	Drop table #tempCommandoutput

create table #tempCommandoutput
(
	CommandOutput varchar(500)
)

delete from #tempCommandoutput

if ( right(@LogFilePath , 1) <> '\')
		set @LogFilePath = @LogFilePath + '\'

set @Command = 'dir ' + @LogFilePath + '/b'

insert into #tempCommandoutput
Exec master..xp_cmdshell @Command

if exists ( select 1 from #tempCommandoutput where CommandOutput = 'The system cannot find the path specified.'  )
Begin
		set @ResultFlag = 1
End

if exists ( select 1 from #tempCommandoutput where CommandOutput = 'The system cannot find the file specified.'  )
Begin
		set @ResultFlag = 1
End

if exists ( select 1 from #tempCommandoutput where CommandOutput = 'The network path was not found.'  )
Begin
		set @ResultFlag = 1
End

Drop table #tempCommandoutput

if ( @ResultFlag = 1)
Begin

		set @ErrorDescription = 'ERROR: Log File Path : '+ @LogFilePath + ' does not exist or is invalid'
		Raiserror('%s' ,16, 1, @ErrorDescription) 
		GOTO ENDPROCESS

End


---------------------------------------------------------------
-- Build the name of the Log File for the current running of 
-- Archive Refresh
---------------------------------------------------------------
Declare @RunDate datetime,
        @CurrentMonth int,
		@CurrentYear int,
		@CurrentTimeStampStr varchar(6),
		@LogFileName varchar(1000)

set @LogFileName = @LogFilePath + 'Med_ArchiveRefresh_' + 
                   replace(replace(replace(convert(varchar(30) ,getdate() , 120), '-' , '') , ' ', ''), ':' , '') +
				   '.log'

------------------------------------------------------------------------------
-- Stop the Formatter Module to prevent locking of tables while archiving data
------------------------------------------------------------------------------

Exec SP_UIMedStopModule -3 , @ErrorDescription Output , @ResultFlag Output

if (@ResultFlag = 1)
Begin

		set @ErrorDescription = 'SP_BSMedArchiveRefresh : '+ convert(varchar(30) ,getdate() , 120) +
								' : ' + @ErrorDescription
		Exec SP_LogMessage @ErrorDescription , @LogFileName -- Logging the original message from the called procedure

		set @ErrorDescription = 'ERROR !!! During firing Semaphore for stopping FORMATTER module'
  
		set @ErrorDescription = 'SP_BSMedArchiveRefresh : '+ convert(varchar(30) ,getdate() , 120) +
								' : ' + @ErrorDescription
		Exec SP_LogMessage @ErrorDescription , @LogFileName

		GOTO ENDPROCESS

End

----------------------------------------------------
-- Check if the Semaphore has been created or not
----------------------------------------------------

Declare @SemaphoreExistsFlag int

set @SemaphoreExistsFlag = 0

Exec SP_UIMedCheckSemaphoreFileExists -3 , @SemaphoreExistsFlag Output ,  @ErrorDescription Output , @ResultFlag Output

if (@ResultFlag = 1)
Begin

		set @ErrorDescription = 'SP_BSMedArchiveRefresh : '+ convert(varchar(30) ,getdate() , 120) +
								' : ' + @ErrorDescription
		Exec SP_LogMessage @ErrorDescription , @LogFileName -- Logging the original message from the called procedure

       	set @ErrorDescription = 'ERROR !!! While checking Semaphore for FORMATTER module'
  
		set @ErrorDescription = 'SP_BSMedArchiveRefresh : '+ convert(varchar(30) ,getdate() , 120) +
								' : ' + @ErrorDescription
		Exec SP_LogMessage @ErrorDescription , @LogFileName -- Logging the error message from the calling procedure

		GOTO ENDPROCESS

End

if ( @SemaphoreExistsFlag = 0 )
Begin

		set @ErrorDescription = 'ERROR !!! Could not create Semaphore for Formatter module'
  
		set @ErrorDescription = 'SP_BSMedArchiveRefresh : '+ convert(varchar(30) ,getdate() , 120) +
								' : ' + @ErrorDescription
		Exec SP_LogMessage @ErrorDescription , @LogFileName

		GOTO ENDPROCESS

End

Else
Begin

		------------------------------------------------------------------------------
		-- If Semaphore exists, then wait for any pending formatter process to finish
		------------------------------------------------------------------------------

		 WAITFOR DELAY '00:02' -- Waiting 2 minutes

End
		

set @RunDate = getdate()
set @CurrentYear = year(@RunDate)
set @CurrentMonth = month(@RunDate)

set @CurrentTimeStampStr = convert(varchar(4) , @CurrentYear) + 
                           right('0' + convert(varchar(2) , @CurrentMonth),2)

---------------------------------------------------------------
-- Check to see that traffic for all months other than current
-- is pushed to archive tables
--------------------------------------------------------------- 

Declare @ArchiveTimeStampStr VarChar(6),
        @ArchiveTableName Varchar(100),
		@SQLStr Varchar(max)

DECLARE db_Refresh_Archive CURSOR FOR 
Select distinct convert(varchar(4) , year(StartTime)) + 
                right('0' + convert(varchar(2) ,Month(StartTime)),2)
from Temp_AllProcessedRecords

OPEN db_Refresh_Archive   
FETCH NEXT FROM db_Refresh_Archive
INTO @ArchiveTimeStampStr

WHILE @@FETCH_STATUS = 0   
BEGIN
  
       if (@ArchiveTimeStampStr = @CurrentTimeStampStr)
	   Begin

				GOTO PROCESSNEXTREC

	   End

	   set @ArchiveTableName = 'Temp_AllProcessedRecords_' + @ArchiveTimeStampStr

	   Begin Try

			   ----------------------------------------------------------------------
			   -- Check to see if the Archive table exists for the time stamp or not
			   ----------------------------------------------------------------------

			   if not exists ( select 1 from sysobjects where name = @ArchiveTableName and xtype = 'U' )
			   Begin

						set @SQLStr = 'Select * into ' + @ArchiveTableName + ' from Temp_AllProcessedRecords where 1 = 2'
						Exec (@SQLStr)

			   End

			   --------------------------------------------------------------------------------
			   -- Delete all those records from the Archive tables which have a refreshed instance
			   -- existing in the Main table
			   ---------------------------------------------------------------------------------

			   set @SQLStr = 
						' Delete tbl2 ' + Char(10) +
						' from Temp_AllProcessedRecords tbl1 ' + Char(10) +
						' inner join ' + @ArchiveTableName + ' tbl2 ' + Char(10) +
						' on tbl1.RecordID = tbl2.RecordID ' + Char(10) +
						' where convert(varchar(4) , year(tbl1.StartTime)) + right(''0'' + convert(varchar(2) ,Month(tbl1.StartTime)),2) = ' + @ArchiveTimeStampStr

			   Exec(@SQLStr)

			   ------------------------------------------------------------------------
			   -- Insert those records from the main table into the archive table which
			   -- do not exist in the archive table
			   ------------------------------------------------------------------------

			   set @SQLStr = 
						' insert into ' + @ArchiveTableName + Char(10) +
						' Select tbl1.* ' + Char(10) +
						' from Temp_AllProcessedRecords tbl1 ' + Char(10) +
						' left join ' + @ArchiveTableName + ' tbl2 ' + Char(10) +
						' on tbl1.RecordID = tbl2.RecordID ' + Char(10) +
						' where tbl2.RecordID is NULL ' + Char(10) +
						' and convert(varchar(4) , year(tbl1.StartTime)) + right(''0'' + convert(varchar(2) ,Month(tbl1.StartTime)),2) = ' + @ArchiveTimeStampStr

			   Exec(@SQLStr)

			   ---------------------------------------------------------------------
			   -- Once all the records are inserted into the Archive table, remove
			   -- them from the main table
			   ---------------------------------------------------------------------

			   set @SQLStr = 
						' Delete tbl1 ' + Char(10) +
						' from Temp_AllProcessedRecords tbl1 ' + Char(10) +
						' inner join ' + @ArchiveTableName + ' tbl2 ' + Char(10) +
						' on tbl1.RecordID = tbl2.RecordID ' + Char(10) +
						' where convert(varchar(4) , year(tbl1.StartTime)) + right(''0'' + convert(varchar(2) ,Month(tbl1.StartTime)),2) = ' + @ArchiveTimeStampStr

			   Exec(@SQLStr)

	   End Try

	   Begin Catch

				set @ErrorDescription = 'ERROR !!! During Archive Refresh of records for CDR Timestamp : ' + @ArchiveTimeStampStr + '. ' + ERROR_MESSAGE()
  
				set @ErrorDescription = 'SP_BSMedArchiveRefresh : '+ convert(varchar(30) ,getdate() , 120) +
										' : ' + @ErrorDescription
				Exec SP_LogMessage @ErrorDescription , @LogFileName

				set @ResultFlag = 1

				CLOSE db_Refresh_Archive  
				DEALLOCATE db_Refresh_Archive

				GOTO ENDPROCESS 

	   End Catch

PROCESSNEXTREC:

	   FETCH NEXT FROM db_Refresh_Archive
	   INTO @ArchiveTimeStampStr 
 
END   

CLOSE db_Refresh_Archive  
DEALLOCATE db_Refresh_Archive

ENDPROCESS:

-------------------------------------------------------------------
-- Remove the Sempahore Created for stopping the Formatter Module
-------------------------------------------------------------------

Exec SP_UIMedStartModule -3 , @ErrorDescription Output , @ResultFlag Output
if (@ResultFlag = 1)
Begin

		set @ErrorDescription = 'SP_BSMedArchiveRefresh : '+ convert(varchar(30) ,getdate() , 120) +
								' : ' + @ErrorDescription
		Exec SP_LogMessage @ErrorDescription , @LogFileName -- Logging the original message from the called procedure

		set @ErrorDescription = 'ERROR !!! During deletion of Semaphore for starting FORMATTER module'
  
		set @ErrorDescription = 'SP_BSMedArchiveRefresh : '+ convert(varchar(30) ,getdate() , 120) +
								' : ' + @ErrorDescription
		Exec SP_LogMessage @ErrorDescription , @LogFileName

End

-------------------------------------------------------
-- Drop all the temporary tables created for processing
-------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempCommandoutput') )
	Drop table #tempCommandoutput

Return




GO
