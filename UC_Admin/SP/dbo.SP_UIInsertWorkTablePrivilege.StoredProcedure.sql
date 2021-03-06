USE [UC_Admin]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIInsertWorkTablePrivilege]    Script Date: 5/2/2020 5:59:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[SP_UIInsertWorkTablePrivilege]
(
	@SessionID varchar(200),
	@Action    varchar(50), -- Valid values DELETE/ADD
	@UserPrivilegeID int,
	@AccessRolesID int,
	@UserID int,
        @ResultFlag int Output,
        @ErrorDescription varchar(200) Output

)
AS


set @ResultFlag = 0

-----------------------------------------------------
-- Get all essential details of the logged in USER
-----------------------------------------------------

Declare @LoggedUserStatusID int,
        @LoggedUserPrivilegeID int


select @LoggedUserStatusID = UserStatusID,
       @LoggedUserPrivilegeID = UserPrivilegeID
from tb_users
where UserID = @UserID


-------------------------------------------------------------
-- Make sure that the logged in user exists in system.
-- This is to cover a corner scenario where logged in user
-- might have been deleted
-------------------------------------------------------------

if ( @LoggedUserStatusID is NULL )                    
Begin

	set @ErrorDescription = 'Logged user does not exist in system repository.Check if user has been removed'
	set @ResultFlag = 1
	
	GOTO PROCESSEND

End

-------------------------------------------------------------
-- Make sure that the logged in user is not in inactive state.
-- This is to cover a corner scenario where looged in user
-- has been inactivated
-------------------------------------------------------------

if ( @LoggedUserStatusID = 2 )                    
Begin

	set @ErrorDescription = 'Inactive user cannot perform any action on privilge profiles'
	set @ResultFlag = 1

	GOTO PROCESSEND

End

------------------------------------------------------------
-- VALIDATION 1: Check if the session user has the essential
-- privilege to create new user
------------------------------------------------------------

Declare @ReturnFlag int

Exec SP_UICheckUserPrivilegeRole @UserID , 'Edit Privilege Profile' , @ReturnFlag output

if (@ReturnFlag = 0)
Begin

	set @ErrorDescription = 'Logged User does not have permissions to edit privilege profiles'
	set @ResultFlag = 1
	
        GOTO PROCESSEND

End

------------------------------------------
-- Make sure that the action is either
-- DELETE or UPDATE
------------------------------------------

if ( @Action not in ('DELETE' , 'ADD' ))
Begin

	set @ErrorDescription = 'The requested Action is not valid. Correct values are DELETE / ADD'
	set @ResultFlag = 1

	GOTO PROCESSEND

End


--------------------------------------------------
-- Insert record into the work table for further 
-- processing
--------------------------------------------------

Begin Try

	insert into wtb_PrivilegeAccessRoles (SessionId , _Action , UserPrivilegeID , AccessRolesID )
	values ( @SessionID , @Action , @UserPrivilegeID , @AccessRolesID ) 

End Try

Begin Catch

	set @ErrorDescription = 'Error !!!!.' +  ERROR_MESSAGE()
	set @ResultFlag = 1

	GOTO PROCESSEND

End Catch


PROCESSEND:

------------------------------------------------------------
-- Incase of an exception, delete all the previous entries
-- for the sesison from the working tables
------------------------------------------------------------

if ( @ResultFlag = 1 )
Begin

	Delete from wtb_PrivilegeAccessRoles where sessionid = @SessionID


End


Return


GO
