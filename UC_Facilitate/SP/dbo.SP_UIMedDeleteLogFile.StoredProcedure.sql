USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIMedDeleteLogFile]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIMedDeleteLogFile]
(
	@AccessScopeID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @LogFilePath varchar(1000),
        @AccessScopeName varchar(500),
		@Cmd varchar(2000)

if not exists ( Select 1 from tb_AccessScope where AccessScopeID = @AccessScopeID )
Begin

		set @ErrorDescription = 'Error !!! The module for which Log File needs to be removed does not exist'
		set @ResultFlag = 1
		return 1

End

select @AccessScopeName = AccessScopeName
from tb_AccessScope
where AccessScopeName = @AccessScopeName

------------------------------------------------------
-- Get the Log File Path from the Config table
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
-- Check if the Semaphore file exists after issuing the command
----------------------------------------------------------------

Declare @FileExists int

set @FileExists = 0

Exec master..xp_fileexist  @LogFilePath , @FileExists output 

If (@FileExists = 1)
Begin

		set @Cmd = 'del ' + '"' + @LogFilePath + '"'
		Exec master..xp_cmdshell @Cmd

End

Else
Begin

		GOTO ENDPROCESS

End

----------------------------------------------------------------------------
-- Double check to see that the log file has been delete successfully
----------------------------------------------------------------------------

set @FileExists = 0

Exec master..xp_fileexist  @LogFilePath , @FileExists output 

If (@FileExists = 1)
Begin

		set @ErrorDescription = 'Error !!! Could not delete the Log file : ' + @LogFilePath
		set @ResultFlag = 1
		return 1

End


ENDPROCESS:

Return 0
GO
