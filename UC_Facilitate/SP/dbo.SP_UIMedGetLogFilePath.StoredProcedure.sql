USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIMedGetLogFilePath]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIMedGetLogFilePath]
(
	@AccessScopeID int,
	@CompleteFilePath varchar(1000) Output,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0
set @CompleteFilePath = NULL

Declare @LogFilePath varchar(1000),
        @AccessScopeName varchar(500)

if not exists ( Select 1 from tb_AccessScope where AccessScopeID = @AccessScopeID )
Begin

		set @ErrorDescription = 'Error !!! The module for which Log File path is requested does not exist'
		set @ResultFlag = 1
		return 1

End

select @AccessScopeName = AccessScopeName
from tb_AccessScope
where AccessScopeName = @AccessScopeName

------------------------------------------------------
-- Get the Semaphore File Path from the Config table
------------------------------------------------------

Select @CompleteFilePath = ConfigValue
from tb_Config
where ConfigName = 'LogFilePath'
and AccessScopeID = @AccessScopeID

if ( @CompleteFilePath is NULL )
Begin

		set @ErrorDescription = 'Error !!! LogFilePath configuration does not exist for module : ' + @AccessScopeName
		set @ResultFlag = 1
		return 1

End

--------------------------------------------------------------------------
-- Ensure that the Log File PAth is a valid folder existing in the system
--------------------------------------------------------------------------

Exec SP_BSValidateConfigParam @AccessScopeID , 'LogFilePath' , @CompleteFilePath,
                              @ErrorDescription Output , @ResultFlag Output


if ( @ResultFlag <> 0 )
Begin

		set @ErrorDescription = 'Error !!! Log File Path does not exist or is invalid. Please check the LOGFILEPATH configuration for the module'
		set @ResultFlag = 1
		set @CompleteFilePath = NULL
		return 1

End

Return 0
GO
