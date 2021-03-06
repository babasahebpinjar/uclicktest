USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIMedCheckLogFileExists]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UIMedCheckLogFileExists]
(
	@AccessScopeID int,
	@LogFileExistsFlag int Output,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0
set @LogFileExistsFlag = 0

Declare @LogFilePath varchar(1000),
        @AccessScopeName varchar(500)

if not exists ( Select 1 from tb_AccessScope where AccessScopeID = @AccessScopeID )
Begin

		set @ErrorDescription = 'Error !!! The module for which Log File check is requested does not exist'
		set @ResultFlag = 1
		return 1

End

select @AccessScopeName = AccessScopeName
from tb_AccessScope
where AccessScopeName = @AccessScopeName

------------------------------------------------------
-- Get the Semaphore File Path from the Config table
------------------------------------------------------

Select @LogFilePath = ConfigValue
from tb_Config
where ConfigName = 'LogFilePath'
and AccessScopeID = @AccessScopeID

if ( @LogFilePath is NULL )
Begin

		set @ErrorDescription = 'Error !!! LogFilePath configuration does not exist for module : ' + @AccessScopeName
		set @ResultFlag = 1
		return 1

End

----------------------------------------------------------------
-- Check if the Log file exists after issuing the command
----------------------------------------------------------------

Declare @FileExists int

set @FileExists = 0

Exec master..xp_fileexist  @LogFilePath , @FileExists output 

If (@FileExists = 1)
Begin

	set @LogFileExistsFlag = 1

End

Return 0
GO
