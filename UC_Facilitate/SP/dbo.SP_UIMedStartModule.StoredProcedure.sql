USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIMedStartModule]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIMedStartModule]
(
	@AccessScopeID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @SemaphoreFilePath varchar(1000),
        @AccessScopeName varchar(500),
		@Cmd varchar(2000)

if not exists ( Select 1 from tb_AccessScope where AccessScopeID = @AccessScopeID )
Begin

		set @ErrorDescription = 'Error !!! The module for which Sempahore needs to be removed does not exist'
		set @ResultFlag = 1
		return 1

End

select @AccessScopeName = AccessScopeName
from tb_AccessScope
where AccessScopeName = @AccessScopeName

------------------------------------------------------
-- Get the Semaphore File Path from the Config table
------------------------------------------------------

Select @SemaphoreFilePath = ConfigValue
from tb_Config
where ConfigName = 'SemaphoreFilePath'
and AccessScopeID = @AccessScopeID

if ( @SemaphoreFilePath is NULL )
Begin

		set @ErrorDescription = 'Error !!! SemaphoreFilePath configuration does not exist for module : ' + @AccessScopeName
		set @ResultFlag = 1
		return 1

End

----------------------------------------------------------------
-- Check if the Semaphore file exists after issuing the command
----------------------------------------------------------------

Declare @FileExists int

set @FileExists = 0

Exec master..xp_fileexist  @SemaphoreFilePath , @FileExists output 

If (@FileExists = 1)
Begin

		set @Cmd = 'del ' + '"' + @SemaphoreFilePath + '"'
		Exec master..xp_cmdshell @Cmd

End

Else
Begin

		GOTO ENDPROCESS

End

----------------------------------------------------------------------------
-- Double check to see that the Semaphore file has been delete successfully
----------------------------------------------------------------------------

set @FileExists = 0

Exec master..xp_fileexist  @SemaphoreFilePath , @FileExists output 

If (@FileExists = 1)
Begin

		set @ErrorDescription = 'Error !!! Could not delete the Semaphore file : ' + @SemaphoreFilePath
		set @ResultFlag = 1
		return 1

End


ENDPROCESS:

Return 0
GO
