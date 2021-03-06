USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSCDRExtractFilePurge]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSCDRExtractFilePurge]
As

Declare @ErrorDescription varchar(2000),
	    @ResultFlag int

set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @CDRExtractFilePurgeDays int

-----------------------------------------------------
-- Get the Purge days for the extract file from the
-- configuration
-----------------------------------------------------

Select @CDRExtractFilePurgeDays = ConfigValue
from ReferenceServer.UC_Admin.dbo.tb_Config
where ConfigName = 'CDRExtractFilePurgeDays'
and AccessScopeID = -8 -- Report

if (@CDRExtractFilePurgeDays is NULL )
	set @CDRExtractFilePurgeDays = 100

--------------------------------------------------
-- Loop through all the Completed CDR Extract files
-- and delete those files where the Extract got
-- completed before the purge days
---------------------------------------------------

Declare @VarCDRExtractID int,
        @CompleteCDRExtractFilePath varchar(500),
		@Command varchar(1000)

DECLARE db_Select_Extract_Files_Purge CURSOR FOR  
Select CDRExtractID
from tb_CDRExtract
where CDRExtractStatusID = -3 -- Extract Completed
and datediff(dd , CDRExtractCompletionDate , getdate() ) > @CDRExtractFilePurgeDays

OPEN db_Select_Extract_Files_Purge
FETCH NEXT FROM db_Select_Extract_Files_Purge
INTO @VarCDRExtractID


WHILE @@FETCH_STATUS = 0   
BEGIN 


		------------------------------------------------
		-- Call the procedure to get the CDR Extract 
		-- File Path
		-------------------------------------------------

		Begin Try

				Exec SP_UIGetCDRExtractFilePath @VarCDRExtractID , 
				                                @CompleteCDRExtractFilePath Output,
												@ErrorDescription Output,
												@ResultFlag Output

				if ( @CompleteCDRExtractFilePath is NULL )
					GOTO PROCESSNEXTREC

		End Try

		Begin Catch

				set @ErrorDescription = 'ERROR !!!! While performing purge activity for CDR Extract : ( ' + convert(varchar(20) , @VarCDRExtractID) + ' ).' + ERROR_MESSAGE()

				CLOSE db_Select_Extract_Files_Purge  
				DEALLOCATE db_Select_Extract_Files_Purge

				RaisError('%s' , 16 , 1 , @ErrorDescription)

				Return 1

        End Catch

		-------------------------------------------
		-- Delete the CDR Extract File from the
		-- Location
		-------------------------------------------

		set @Command = 'del '+ @CompleteCDRExtractFilePath
		exec master..xp_cmdshell @Command 

PROCESSNEXTREC:

		FETCH NEXT FROM db_Select_Extract_Files_Purge
		INTO @VarCDRExtractID

END

CLOSE db_Select_Extract_Files_Purge  
DEALLOCATE db_Select_Extract_Files_Purge 

Return 0
GO
