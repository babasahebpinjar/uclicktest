USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIMedCheckSemaphoreFileExists]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UIMedCheckSemaphoreFileExists]
(
	@AccessScopeID int,
	@SempahoreExistsFlag int Output,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0
set @SempahoreExistsFlag = 0

Declare @SemaphoreFilePath varchar(1000),
        @AccessScopeName varchar(500)

if not exists ( Select 1 from tb_AccessScope where AccessScopeID = @AccessScopeID )
Begin

		set @ErrorDescription = 'Error !!! The module for which Sempahore check is requested does not exist'
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

	set @SempahoreExistsFlag = 1

End

Return 0
GO
