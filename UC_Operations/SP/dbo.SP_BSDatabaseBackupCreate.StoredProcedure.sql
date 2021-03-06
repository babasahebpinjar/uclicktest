USE [UC_Operations]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSDatabaseBackupCreate]    Script Date: 5/2/2020 6:25:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_BSDatabaseBackupCreate]
(
	@InstanceID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @DatabaseName varchar(100),
        @BackupLocation varchar(1000),
		@BackupName varchar(100),
		@BackupFile varchar(100),
		@cmd varchar(2000)

-----------------------------------------------
-- Extract the essential parameters for Backup
-----------------------------------------------

Exec REFERENCESERVER.UC_Operations.dbo.SP_BSGetObjectParamValue @InstanceID , 'Database Backup Path' , @BackupLocation Output

if ( @BackupLocation is NULL )
Begin
	
		set @ErrorDescription = 'ERROR !!!! Database Backup Path is not defined for object'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End

--------------------------------------------------
-- check if the backup location exists or not and
-- is it accessible
---------------------------------------------------

if ( RIGHT(@BackupLocation , 1) <> '\' )
     set @BackupLocation = @BackupLocation + '\'

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempCommandoutput') )
	Drop table #tempCommandoutput

create table #tempCommandoutput
(
  CommandOutput varchar(500)
)

set @cmd = 'dir ' + '"' + @BackupLocation + '"' + '/b'
--print @cmd

insert into #tempCommandoutput
	Exec master..xp_cmdshell @cmd
	

if exists ( 
		select 1 from #tempCommandoutput
		where CommandOutput in (
					 'The system cannot find the file specified.',
					 'The system cannot find the path specified.',
					 'The network path was not found.',
					 'Access is denied.',
					 'File Not Found'
				       )								
          )		
Begin  

      Select @ErrorDescription = 'ERROR !!! ' + CommandOutput
	  from #tempCommandoutput
	  where CommandOutput is not NULL

	  set @ResultFlag = 1

	  GOTO ENDPROCESS

End

------------------------
-- Fetch Database Name
------------------------

Exec REFERENCESERVER.UC_Operations.dbo.SP_BSGetObjectParamValue @InstanceID , 'Database Name' , @DatabaseName Output

if ( @DatabaseName is NULL )
Begin
	
		set @ErrorDescription = 'ERROR !!!! Database Name is not defined for object'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End

------------------------------------
-- Fetch Database Backup Name
------------------------------------

Exec REFERENCESERVER.UC_Operations.dbo.SP_BSGetObjectParamValue @InstanceID , 'Database Backup Name' , @BackupName Output

if ( @BackupName is NULL )
Begin
	
		set @ErrorDescription = 'ERROR !!!! Database Backup Name is not defined for object'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End

--------------------------------------
-- Create the name of the back up file
---------------------------------------

set @BackupFile = @DatabaseName + '.bak'



Declare @SQLStr nvarchar(max),
        @AbsoluteBackupPath varchar(1000),
		@FileExists int

if ( right(@BackupLocation , 1) <> '\' )
    set @BackupLocation = @BackupLocation + '\'

set @AbsoluteBackupPath = @BackupLocation + @BackupFile

------------------------------------------------------
-- Delete the old back up file from the location
-- before initiating a new backup
------------------------------------------------------

set @FileExists = 0

Exec master..xp_fileexist @AbsoluteBackupPath , @FileExists output  

if ( @FileExists = 1 )
Begin

	set @cmd = 'del ' + '"' + @AbsoluteBackupPath + '"'
	exec master..xp_cmdshell @cmd

End 



Begin Try


		set @SQLStr = 'BACKUP DATABASE ' + @DatabaseName +  char(10) +
					  ' TO DISK = ''' + @AbsoluteBackupPath + ''' ' + char(10) +
					  ' WITH NOFORMAT, NOINIT,  NAME ='''+ @BackupName + ''',' + char(10) +
					  ' SKIP, NOREWIND, NOUNLOAD,  STATS = 10'

		print @SQLStr

		Exec(@SQLStr)

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!!! While creating database backup. ' + ERROR_MESSAGE()
		set @ResultFlag = 1

		GOTO ENDPROCESS

End Catch


ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempCommandoutput') )
	Drop table #tempCommandoutput

Return 0

GO
