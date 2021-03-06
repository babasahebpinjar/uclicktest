USE [UC_Admin]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICreateNewPrivilege]    Script Date: 5/2/2020 5:59:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Procedure [dbo].[SP_UICreateNewPrivilege]
(
     @Privilege varchar(50),
     @UserID int,
     @ResultFlag int Output,
     @ErrorDescription varchar(200) Output
)
--With Encryption
As


set @ErrorDescription = NULL
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
	return

End

-------------------------------------------------------------
-- Make sure that the logged in user is not in inactive state.
-- This is to cover a corner scenario where looged in user
-- has been inactivated
-------------------------------------------------------------

if ( @LoggedUserStatusID = 2 )                    
Begin

	set @ErrorDescription = 'Inactive user cannot create new privilege profile'
	set @ResultFlag = 1
	return

End


-----------------------------------------------
-- Perform essential validations on all the 
-- input parameters before proceeding with
-- update
-----------------------------------------------

------------------------------------------------------------
-- VALIDATION 1: Check if the session user has the essential
-- privilege to create new user
------------------------------------------------------------

Declare @ReturnFlag int

Exec SP_UICheckUserPrivilegeRole @UserID , 'Create New Privilege Profile' , @ReturnFlag output

if (@ReturnFlag = 0)
Begin

	set @ErrorDescription = 'Logged User does not have privilege to create new users'
	set @ResultFlag = 1
	return

End

------------------------------------------------------------
-- VALIDATION 1: Check to ensure that the privilege name 
-- is unique
------------------------------------------------------------

if exists ( select 1 from tb_UserPrivilege where ltrim(rtrim(UserPrivilege)) = ltrim(rtrim(@Privilege)))
Begin

	set @ErrorDescription = 'Privilege name is not unique. Already a privilege profile exists in the system with name: ( ' + rtrim(ltrim(@Privilege)) + ' )'
	set @ResultFlag = 1
	return

End

--------------------------------
-- insert new privilege record
--------------------------------

Begin Try

	insert into tb_UserPrivilege (  UserPrivilege )
	values ( @Privilege )

End Try

Begin Catch

	set @ErrorDescription = ERROR_MESSAGE()
	set @ResultFlag = 1
	return

End Catch

Return
GO
