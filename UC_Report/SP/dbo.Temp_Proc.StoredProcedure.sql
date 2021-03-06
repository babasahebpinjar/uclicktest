USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[Temp_Proc]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Temp_Proc]
as

Declare @DatabaseName varchar(100),
        @BackupLocation varchar(1000),
		@BackupName varchar(100),
		@BackupFile varchar(100),
		@ErrorDescription varchar(2000),
		@ResultFlag int

set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @SQLStr nvarchar(max),
        @AbsoluteBackupPath varchar(1000)

set @DatabaseName = 'UC_Report'
set @BackupLocation = '\\10.23.51.62\f$\Uclick_Product_Suite'
set @BackupFile = 'UC_Report.bak'
set @BackupName = 'UC_Report-Full Database Backup'

if ( right(@BackupLocation , 1) <> '\' )
    set @BackupLocation = @BackupLocation + '\'

set @AbsoluteBackupPath = @BackupLocation + @BackupFile

Begin Try


		set @SQLStr = 'BACKUP DATABASE ' + @DatabaseName +  char(10) +
					  ' TO DISK = ''' + @AbsoluteBackupPath + ''' ' + char(10) +
					  ' WITH NOFORMAT, NOINIT,  NAME ='''+ @BackupName + ''',' + char(10) +
					  ' SKIP, NOREWIND, NOUNLOAD,  STATS = 10'

		print @SQLStr

		--insert into #TempCommandOutput
		Exec(@SQLStr)

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!!! While creating database backup. ' + ERROR_MESSAGE()
		set @ResultFlag = 1

		GOTO ENDPROCESS

End Catch


ENDPROCESS:

select @ErrorDescription , @ResultFlag

Return 0

GO
