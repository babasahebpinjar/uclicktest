USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMasterlogCollector_OAM_B]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_BSMasterlogCollector_OAM_B]
(
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As


Declare @AccessScopeID int ,
        @AbsoluteLogFilePath varchar(1000),
		@SourceFilePath varchar(1000),
		@SourceFileIdentifier varchar(1000),
		@SemaphoreFilePath varchar(1000),
		@FileExists int


set @ErrorDescription = NULL
set @ResultFlag = 0

--------------------------------------------------------
-- Get the Access Scope for the Collector module and 
-- check if all the config parameters defined are valid
-- or not
--------------------------------------------------------

Select @AccessScopeID = AccessScopeID
from TB_Masterlog_AccessScope
where AccessScopeName = 'MasterlogCollector'


if (@AccessScopeID is NULL) 
Begin

	set @ErrorDescription = 'ERROR !!!! Please create an entry for the COLLECTOR (MasterlogCollector) module in the Access Scope schema'
	RaisError('%s' , 16,1 , @ErrorDescription)
	set @ResultFlag = 1
	Return 1

End

--------------------------------------------------------
-- Validate the Configuration parameters to ensure that
-- no exceptions exist
--------------------------------------------------------

Exec SP_BSValidateConfig @AccessScopeID , @ErrorDescription Output , @ResultFlag Output

if (@ResultFlag = 1)
Begin

	set @ErrorDescription = 'ERROR !!!! Validating Configuration parameters for COLLECTOR  module.' + @ErrorDescription
	RaisError('%s' , 16, 1, @ErrorDescription)
	set @ResultFlag = 1
	Return 1

End

--------------------------------------------------------
-- EXTRACT LOG FILE PATH DEFINED IN CONFIG SCHEMA     --
--------------------------------------------------------

select @AbsoluteLogFilePath = ConfigValue
from TB_Masterlog_Config
where ConfigName = 'LogFilePath'
and AccessScopeID = @AccessScopeID

-------------------------------------------------------------
-- GET ALL THE DATA RELATED FTP OF CDR FILES FROM SERVER --
-------------------------------------------------------------

Declare @FileNameTag varchar(1000),
        @FTPSiteIPAddress varchar(1000),
        @FTPSiteUsername varchar(1000),
        @FTPSitePassword varchar(1000),
        @WorkDirectory varchar(1000),
        @FTPSiteDirectory varchar(1000),
        @FTPExecutablePath varchar(1000)

select @FileNameTag = ConfigValue
from TB_Masterlog_Config
where ConfigName = 'FileNameTag'
and AccessScopeID = @AccessScopeID


select @FTPSiteIPAddress = ConfigValue
from TB_Masterlog_Config
where ConfigName = 'FTPSiteIPAddress_OAM_B'
and AccessScopeID = @AccessScopeID


select @FTPSiteUsername = ConfigValue
from TB_Masterlog_Config
where ConfigName = 'FTPSiteUsername_OAM_B'
and AccessScopeID = @AccessScopeID

select @FTPSitePassword = ConfigValue
from TB_Masterlog_Config
where ConfigName = 'FTPSitePassword_OAM_B'
and AccessScopeID = @AccessScopeID


select @WorkDirectory = ConfigValue
from TB_Masterlog_Config
where ConfigName = 'WorkDirectory'
and AccessScopeID = @AccessScopeID


select @FTPSiteDirectory = ConfigValue
from TB_Masterlog_Config
where ConfigName = 'FTPSiteDirectory_OAM_B'
and AccessScopeID = @AccessScopeID


select @FTPExecutablePath = ConfigValue
from TB_Masterlog_Config
where ConfigName = 'FTPExecutablePath'
and AccessScopeID = @AccessScopeID


----------------------------------------------------------------------
-- Get Path of all the executables for Uncompression and Encryption
----------------------------------------------------------------------

Declare @UnCompressExecutablePath varchar(1000),
        @MasterlogExtensionPartOfOriginalFile int,
		@CompressionExtension varchar(1000),
		@MasterlogFileExtension varchar(1000),
		@OutputFolderPath varchar(1000)

select @UnCompressExecutablePath = ConfigValue
from TB_Masterlog_Config
where ConfigName = 'UnCompressExecutablePath'
and AccessScopeID = @AccessScopeID

select @MasterlogExtensionPartOfOriginalFile = ConfigValue
from TB_Masterlog_Config
where ConfigName = 'MasterlogExtensionPartOfOriginalFile'
and AccessScopeID = @AccessScopeID

select @CompressionExtension = ConfigValue
from TB_Masterlog_Config
where ConfigName = 'CompressionExtension'
and AccessScopeID = @AccessScopeID

select @MasterlogFileExtension = ConfigValue
from TB_Masterlog_Config
where ConfigName = 'MasterlogFileExtension'
and AccessScopeID = @AccessScopeID

select @OutputFolderPath = ConfigValue
from TB_Masterlog_Config
where ConfigName = 'OutputFolderPath'
and AccessScopeID = @AccessScopeID

--------------------------------------------------------------------
-- Check if Semaphore exists, indicating that the process should
-- not run
--------------------------------------------------------------------

select @SemaphoreFilePath = ConfigValue
from TB_Masterlog_Config
where ConfigName = 'SemaphoreFilePath'
and AccessScopeID = @AccessScopeID

set @FileExists = 0
        
Exec master..xp_fileexist @SemaphoreFilePath , @FileExists output 

if ( @FileExists = 1 )
Begin
		     
	set @ErrorDescription = 'SP_BSMasterlogCollectorStandby : '+ convert(varchar(30) ,getdate() , 120) +
	                        ' : ' + ' INFO !!! Semaphore exists for suspending Collecctor'
    Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

	GOTO ENDPROCESS

End

----------------------------------------------------------
-- Call the process to check the FTP connection strings
----------------------------------------------------------

Declare @FTPErrorFlag int = 0

Begin Try            

		Exec SP_BSCollectorCheckFTPConnection @FTPSiteIPAddress, @FTPSiteUSerName,
		                                      @FTPSitePassword , @WorkDirectory,
											  @FTPExecutablePath, @FTPSiteDirectory,
											  @FTPErrorFlag Output

End Try

Begin Catch

		set @ErrorDescription = 'SP_BSCollectorCheckFTPConnection : '+ convert(varchar(30) ,getdate() , 120) +
								' : ' + ' ERROR !!! Exception occurred during checking of FTP credentials' + ERROR_MESSAGE()
		Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

		set @ResultFlag = 1

		GOTO ENDPROCESS

End Catch

if ( @FTPErrorFlag = 10 or @FTPErrorFlag = 40 )
Begin

     RaisError('ERROR:Connecting to FTP site.',16,1)

     set @ErrorDescription = 'SP_BSCollectorCheckFTPConnection : '+ convert(varchar(30) ,getdate() , 120)+ ' : ' + ' Error Connecting to FTP site. Check FTP User credentials'

	 Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

	 set @ResultFlag = 1

	 GOTO ENDPROCESS

End

if ( @FTPErrorFlag = 20 )
Begin

     RaisError('ERROR:Connecting to FTP site.',16,1)

     set @ErrorDescription = 'SP_BSCollectorCheckFTPConnection : '+ convert(varchar(30) ,getdate() , 120)+ ' : ' + ' Connecting to FTP site. Problem due to network connection'

	 Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

	 set @ResultFlag = 1

	 GOTO ENDPROCESS

End

if ( @FTPErrorFlag = 30 )
Begin

     RaisError('ERROR:Connecting to FTP site.',16,1)

     set @ErrorDescription = 'SP_BSCollectorCheckFTPConnection : '+ convert(varchar(30) ,getdate() , 120)+ ' : ' + ' Connecting to FTP site. Host SFTP server doe not exist'

	 Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

	 set @ResultFlag = 1

	 GOTO ENDPROCESS

End

if ( @FTPErrorFlag = 50 )
Begin

     RaisError('ERROR:Connecting to FTP site.',16,1)
     
     set @ErrorDescription = 'SP_BSCollectorCheckFTPConnection : '+ convert(varchar(30) ,getdate() , 120)+ ' : ' + ' Connecting to FTP site.FTP server directory is not valid'

	 Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

	 set @ResultFlag = 1

	 GOTO ENDPROCESS

End


-------------------------------------------------------------------------
-- Get list of all Masterlog files, which qualify as per the File name tag
-------------------------------------------------------------------------

set @MasterlogExtensionPartOfOriginalFile = isnull(@MasterlogExtensionPartOfOriginalFile, 0)

--------------------------------------------------------
-- Create temporary table to store all the possible
-- file names.
--------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tmpOutputGetLisOfCDRFiles') )
		Drop table #tmpOutputGetLisOfMasterlogFiles

create table #tmpOutputGetLisOfMasterlogFiles ( rowdata varchar(1000) )

set @ErrorDescription = NULL
set @ResultFlag = 0

Begin Try            

		Exec SP_BSCollectorGetNamesOfFTPFiles @FileNameTag ,@FTPSiteIPAddress, @FTPSiteUSerName,
		                                      @FTPSitePassword , @WorkDirectory,
											  @FTPSiteDirectory, @FTPExecutablePath, 
											  @AbsoluteLogFilePath ,
											  @ErrorDescription Output,
											  @ResultFlag Output

		--Select 'DEBUG 2: After Getting names of all files from FTP site' as status
		--Select RowData
		--from #tmpOutputGetLisOfCDRFiles

End Try

Begin Catch

		set @ErrorDescription = 'SP_BSCollectorGetNamesOfFTPFiles : '+ convert(varchar(30) ,getdate() , 120) +
								' : ' + ' ERROR !!! While getting list of all Masterlog Files from Network Location' + ERROR_MESSAGE()
		Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

		set @ResultFlag = 1

		GOTO ENDPROCESS

End Catch

if (@ResultFlag = 1)
Begin

		set @ErrorDescription = 'SP_BSMasterlogCollectorStandby : '+ convert(varchar(30) ,getdate() , 120) +
								' : ' + ' ERROR !!! While getting list of all CDR Files from Network Location'
		Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

		set @ResultFlag = 1

		GOTO ENDPROCESS

End



-------------------------------------------------------------------
-- Remove records for those CDR files, which are already existing in
-- the Collector statistics table
--------------------------------------------------------------------

if (@MasterlogExtensionPartOfOriginalFile = 1)
Begin

	--Select 'Debug 2 : ' + RowData , substring(rowData , 1  , len(rowData) - len(@CompressionExtension) - len(@CDRFileExtension))
	--from #tmpOutputGetLisOfCDRFiles

	Delete tbl1
	from #tmpOutputGetLisOfMasterlogFiles tbl1
	inner join tb_MasterlogCollectorStatistics tbl2
	   on substring(tbl1.rowData , 1  , len(tbl1.rowData) - len(@CompressionExtension) - len(@MasterlogFileExtension)) = tbl2.MasterlogFileName

End

else
Begin

	--Select 'Debug 2 : ' + RowData , substring(rowData , 1  , len(rowData) - len(@CompressionExtension))
	--from #tmpOutputGetLisOfCDRFiles

	Delete tbl1
	from #tmpOutputGetLisOfMasterlogFiles tbl1
	inner join tb_MasterlogCollectorStatistics tbl2
	   on substring(tbl1.rowData , 1  , len(tbl1.rowData) - len(@CompressionExtension)) = tbl2.MasterlogFileName

End

--------------------------------------------------------------------------
-- Added Code 18th Nov 2018
-- this is to handle scenario where the file in the switch location may
-- be present in unzipped extracted form already by mistake. This results
-- in the uncompress third party application to get hung
---------------------------------------------------------------------------

if ( len(@CompressionExtension) > 0 )
Begin

		Delete from #tmpOutputGetLisOfMasterlogFiles
		where reverse(substring(reverse(rowData) , 1 ,  len(@CompressionExtension))) <> @CompressionExtension

End

--Select 'Debug : ' + RowData as Result
--from #tmpOutputGetLisOfCDRFiles


--------------------------------------------------------------------
-- Call the procedure to FTP all the left over relevant files from
-- FTP location
--------------------------------------------------------------------

set @ErrorDescription = NULL
set @ResultFlag = 0
          

Exec SP_BSCollectorExportMasterlogFiles     @FTPSiteIPAddress, @FTPSiteUSerName,
		                                @FTPSitePassword , @WorkDirectory,
										@FTPSiteDirectory, @FTPExecutablePath, 
										@CompressionExtension ,@MasterlogExtensionPartOfOriginalFile, @MasterlogFileExtension,
										@UnCompressExecutablePath , @OutputFolderPath,
										@AbsoluteLogFilePath ,
										@ErrorDescription Output,
										@ResultFlag Output



if (@ResultFlag = 1)
Begin

		set @ErrorDescription = 'SP_BSMasterlogCollectorStandby : '+ convert(varchar(30) ,getdate() , 120) +
								' : ' + ' ERROR !!! While Exporting Masterlog files from the FTP Location'
		Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

		set @ResultFlag = 1

		GOTO ENDPROCESS

End


ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tmpOutputGetLisOfMasterlogFiles') )
		Drop table #tmpOutputGetLisOfMasterlogFiles

Return 0


GO
