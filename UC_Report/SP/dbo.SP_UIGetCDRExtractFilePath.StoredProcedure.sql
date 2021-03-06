USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetCDRExtractFilePath]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetCDRExtractFilePath]
(
	@CDRExtractID int,
	@CompleteExtractFileName varchar(500) Output,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ResultFlag = 0
set @ErrorDescription = NULL

Declare @cmd varchar(2000),
        @CDRExtractDirectory varchar(1000),
		@CDRExtractFileName varchar(500),
		@AbsoluteFilePath varchar(100),
		@FileExists int

--------------------------------------------------------------------------------
-- Check to see if the CDR Extract exists in the system ad in Completed state
---------------------------------------------------------------------------------

if not exists ( select 1 from tb_CDRExtract where CDRExtractID = @CDRExtractID and CDRExtractStatusID = -3 )
Begin

		set @ErrorDescription = 'ERROR !!!! CDR Extract does not exist in system, or is not in completed state'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End

---------------------------------------------------------
-- Get the configured extract folder from config table
---------------------------------------------------------

select @CDRExtractDirectory = ConfigValue 
from ReferenceServer.UC_Admin.dbo.tb_Config
where ConfigName = 'CDRExtractPath'
and AccessScopeID = -8 -- BI Reporting


if ( @CDRExtractDirectory is NULL )
Begin

		set @ErrorDescription = 'ERROR !!!! CDR Extract Directory configuration (CDRExtractPath) is missing'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End

if ( @CDRExtractDirectory is NULL )
Begin

	set @CDRExtractDirectory = ''
End

if ( RIGHT(@CDRExtractDirectory , 1) <> '\' )
     set @CDRExtractDirectory = @CDRExtractDirectory + '\'


create table #tempCommandoutput
(
  CommandOutput varchar(500)
)

set @cmd = 'dir ' + '"' + @CDRExtractDirectory + '"' + '/b'
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


drop table #tempCommandoutput

------------------------------------------------------------
-- Extract the CDR Extract File Name fron the tb_CDRExtract
-- schema and then form the complete file name
-------------------------------------------------------------

select @CDRExtractFileName =  CDRExtractFileName
from tb_CDRExtract
where CDRExtractID = @CDRExtractID

if ( @CDRExtractFileName is NULL )
Begin

		set @ErrorDescription = 'ERROR !!!! CDR Extract File does not exist for theparticular Extract'
		set @ResultFlag = 1

		GOTO ENDPROCESS

End

set @AbsoluteFilePath = @CDRExtractDirectory + @CDRExtractFileName

set @FileExists = 0

Exec master..xp_fileexist @AbsoluteFilePath , @FileExists output  

if ( @FileExists <> 1 )
Begin

   set @ErrorDescription = 'ERROR !!! CDR extract file  : ( ' + @AbsoluteFilePath + ' ) does not exist or has been purged'
   set @ResultFlag = 1

   GOTO ENDPROCESS

End 

Else
Begin

   set @CompleteExtractFileName = @AbsoluteFilePath 
  
End 


ENDPROCESS:

if (@ResultFlag = 1)
	set @CompleteExtractFileName = NULL

Return 0

GO
