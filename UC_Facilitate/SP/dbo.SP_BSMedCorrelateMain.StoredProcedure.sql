USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMedCorrelateMain]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSMedCorrelateMain]
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
-- Get the Access Scope for the Correlate module and 
-- check if all the config parameters defined are valid
-- or not
--------------------------------------------------------

Select @AccessScopeID = AccessScopeID
from tb_AccessScope
where AccessScopeName = 'MedCorrelate'


if (@AccessScopeID is NULL) 
Begin

	set @ErrorDescription = 'ERROR !!!! Please create an entry for the CORRELATION (MedCorrelate) module in the Access Scope schema'
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

	set @ErrorDescription = 'ERROR !!!! Validating Configuration parameters for CORRELATOR  module'
	RaisError('%s' , @ErrorDescription , 16, 1)
	set @ResultFlag = 1
	Return 1

End

--------------------------------------------------------
-- EXTRACT LOG FILE PATH DEFINED IN CONFIG SCHEMA     --
--------------------------------------------------------

select @AbsoluteLogFilePath = ConfigValue
from tb_Config
where ConfigName = 'LogFilePath'
and AccessScopeID = @AccessScopeID

-------------------------------------------------------------
-- GET THE SOURCE DIRECTORY AND FILE IDENTIFIER PARAMETERS --
-------------------------------------------------------------

select @SourceFilePath = ConfigValue
from tb_Config
where ConfigName = 'SourceFilePath'
and AccessScopeID = @AccessScopeID

select @SourceFileIdentifier = ConfigValue
from tb_Config
where ConfigName = 'SourceFileIdentifier'
and AccessScopeID = @AccessScopeID

--------------------------------------------------------------------
-- Check if Semaphore exists, indicating that the process should
-- not run
--------------------------------------------------------------------
select @SemaphoreFilePath = ConfigValue
from tb_Config
where ConfigName = 'SemaphoreFilePath'
and AccessScopeID = @AccessScopeID

set @FileExists = 0
        
Exec master..xp_fileexist @SemaphoreFilePath , @FileExists output 

if ( @FileExists = 1 )
Begin
		     
	set @ErrorDescription = 'SP_BSMedCorrelateMain : '+ convert(varchar(30) ,getdate() , 120) +
	                        ' : ' + ' INFO !!! Semaphore exists for suspending Correlation'
    Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

	GOTO ENDPROCESS

End

----------------------------------------------------------------------------------------------------
-- *********************************  COLLECT CDR FILES FROM LOCATION ************************** --
----------------------------------------------------------------------------------------------------

---------------------------------------------------------------------
-- Call the Procedure to collect all the files from the Source Path
---------------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempMdCorrelateCollect') )
	Drop table #TempMdCorrelateCollect

create table #TempMedCorrelateCollect
(
    CDRFileName varchar(500)
)

Begin Try

	Exec SP_BSMedCorrelateCollect @SourceFilePath , @SourceFileIdentifier , @AbsoluteLogFilePath,
								  @ErrorDescription Output , @ResultFlag Output

End Try

Begin Catch

	set @ErrorDescription = 'SP_BSMedCorrelateCollect : '+ convert(varchar(30) ,getdate() , 120) +
	                        ' : ' + ' ERROR !!! ' + ERROR_MESSAGE()
    Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

    set @ResultFlag = 1
	GOTO ENDPROCESS

End Catch

if ( @ResultFlag = 1 )
Begin

	set @ErrorDescription = 'SP_BSMedCorrelateMain : '+ convert(varchar(30) ,getdate() , 120) +
	                        ' : ' + ' ERROR !!! during file collection process'
    Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

	GOTO ENDPROCESS

End

---------------------------------
-- For Debugging Puerpose Start
---------------------------------
--select * from #TempMedCorrelateCollect
------------------------------
-- For Debugging Prupose End
------------------------------

------------------------------------------------------------------------------------------------------------
-- *********************************  STORE DATA FROM CDR FILES INTO DB TABLES ************************** --
------------------------------------------------------------------------------------------------------------

Declare @CDRFileName varchar(200)

-------------------------------------------------------------------
-- Open the cursor to read each file name from the temp table and
-- pass it to the SP for storing the records in I, O, Z tables
-- before mapping
-------------------------------------------------------------------

DECLARE db_Store_CDR_File CURSOR FOR 
select CDRFileName
from #TempMedCorrelateCollect 

OPEN db_Store_CDR_File   
FETCH NEXT FROM db_Store_CDR_File
INTO @CDRFileName

WHILE @@FETCH_STATUS = 0   
BEGIN 

        --------------------------------------------------
		-- Check for Semaphore before processing each file
		-------------------------------------------------- 

		set @FileExists = 0
        
		Exec master..xp_fileexist @SemaphoreFilePath , @FileExists output 

		if ( @FileExists = 1 )
		Begin
		     
			set @ErrorDescription = 'SP_BSMedCorrelateMain : '+ convert(varchar(30) ,getdate() , 120) +
									' : ' + ' INFO !!! Semaphore exists for suspending Correlation'
			Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

			CLOSE db_Store_CDR_File  
			DEALLOCATE db_Store_CDR_File

			GOTO ENDPROCESS

		End  

		-------------------------------------------------------
		-- Process CDR file and upload records into database
		-------------------------------------------------------
				
		Begin Try

			Exec SP_BSMedCorrelateStore  @AccessScopeID ,@SourceFilePath ,@CDRFileName , @AbsoluteLogFilePath, 
			                             @ErrorDescription Output , @ResultFlag Output

		End Try

		Begin Catch

			set @ErrorDescription = 'SP_BSMedCorrelateStore : '+ convert(varchar(30) ,getdate() , 120) +
									' : ' + ERROR_MESSAGE()
			Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

			CLOSE db_Store_CDR_File  
			DEALLOCATE db_Store_CDR_File

			set @ResultFlag = 1

			GOTO ENDPROCESS

		End Catch

		if ( @ResultFlag = 1 )
		Begin

			set @ErrorDescription = 'SP_BSMedCorrelateMain : '+ convert(varchar(30) ,getdate() , 120) +
									' : ' + ' ERROR !!! during storage of file records in DB'
			Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

		End		     

	   FETCH NEXT FROM db_Store_CDR_File
	   INTO @CDRFileName 
 
END   

CLOSE db_Store_CDR_File  
DEALLOCATE db_Store_CDR_File

-------------------------------------------------------------------------------------------------------
-- *********************************  MAP RECORDS TO FORM O/P CDR RECORDS ************************** --
-------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- Check for Semaphore before mapping I, O and Z records to create output record
---------------------------------------------------------------------------------- 

set @FileExists = 0
        
Exec master..xp_fileexist @SemaphoreFilePath , @FileExists output 

if ( @FileExists = 1 )
Begin
		     
	set @ErrorDescription = 'SP_BSMedCorrelateMain : '+ convert(varchar(30) ,getdate() , 120) +
							' : ' + ' INFO !!! Semaphore exists for suspending Correlation'
	Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

	CLOSE db_Store_CDR_File  
	DEALLOCATE db_Store_CDR_File

	GOTO ENDPROCESS

End 

------------------------------------------------------------------
-- Call the procedure to initiate mapping of I, O and Z records 
------------------------------------------------------------------

Begin Try

	Exec  SP_BSMedCorrelateMapBER @AbsoluteLogFilePath,
								  @ErrorDescription Output , 
								  @ResultFlag Output

End Try

Begin Catch

	set @ErrorDescription = 'SP_BSMedCorrelateMapBER : '+ convert(varchar(30) ,getdate() , 120) +
	                        ' : ' + ' ERROR !!! ' + ERROR_MESSAGE()
    Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

    set @ResultFlag = 1
	GOTO ENDPROCESS

End Catch

if ( @ResultFlag = 1 )
Begin

	set @ErrorDescription = 'SP_BSMedCorrelateMain : '+ convert(varchar(30) ,getdate() , 120) +
	                        ' : ' + ' ERROR !!! during mapping of I, O and Z records for creating CDR record'
    Exec SP_LogMessage @ErrorDescription , @AbsoluteLogFilePath

	GOTO ENDPROCESS

End


ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempMdCorrelateCollect') )
	Drop table #TempMdCorrelateCollect

Return 0





GO
