USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetMasterLogExtractFilePath]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetMasterLogExtractFilePath]
(
	@MasterLogExtractID int,
	@CompleteExtractFileName varchar(500) Output,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ResultFlag = 0
set @ErrorDescription = NULL

Declare @cmd varchar(2000),
        @MasterLogExtractDirectory varchar(1000),
		@MasterLogExtractFileName varchar(500),
		@AbsoluteFilePath varchar(100),
		@FileExists int

--------------------------------------------------------------------------------
-- Check to see if the Master Log Extract exists in the system ad in Completed state
---------------------------------------------------------------------------------

if not exists ( select 1 from tb_masterlogextract where masterlogextractid = @MasterLogExtractID and MasterlogExtractStatusID = -3 )
Begin

		set @ErrorDescription = 'ERROR !!!! Master Log Extract does not exist in system, or is not in completed state'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End
 

---------------------------------------------------------
-- Get the configured extract folder from config table
---------------------------------------------------------

select @MasterLogExtractDirectory = ConfigValue 
from ReferenceServer.UC_Admin.dbo.tb_Config
where ConfigName = 'MasterLogExtractPath'
and AccessScopeID = -8 -- BI Reporting


if ( @MasterLogExtractDirectory is NULL )
Begin

		set @ErrorDescription = 'ERROR !!!! Master Log Extract Directory configuration (MasterLogExtractPath) is missing'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End

if ( @MasterLogExtractDirectory is NULL )
Begin

	set @MasterLogExtractDirectory = ''
End

if ( RIGHT(@MasterLogExtractDirectory , 1) <> '\' )
     set @MasterLogExtractDirectory = @MasterLogExtractDirectory + '\'


create table #tempCommandoutput
(
  CommandOutput varchar(500)
)

set @cmd = 'dir ' + '"' + @MasterLogExtractDirectory + '"' + '/b'
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
-- Extract the MasterLog Extract File Name fron the tb_MasterLogExtract
-- schema and then form the complete file name
-------------------------------------------------------------

select @MasterLogExtractFileName =  MasterlogExtractFileName
from tb_masterlogextract
where masterlogextractid = @MasterLogExtractID

if ( @MasterLogExtractFileName is NULL )
Begin

		set @ErrorDescription = 'ERROR !!!! Master Log Extract File does not exist for theparticular Extract'
		set @ResultFlag = 1

		GOTO ENDPROCESS

End

set @AbsoluteFilePath = @MasterLogExtractDirectory + @MasterLogExtractFileName

set @FileExists = 0

Exec master..xp_fileexist @AbsoluteFilePath , @FileExists output  

if ( @FileExists <> 1 )
Begin

   set @ErrorDescription = 'ERROR !!! Master Log extract file  : ( ' + @AbsoluteFilePath + ' ) does not exist or has been purged'
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
