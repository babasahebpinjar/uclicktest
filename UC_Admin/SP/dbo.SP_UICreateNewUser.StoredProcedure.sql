USE [UC_Admin]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICreateNewUser]    Script Date: 5/2/2020 5:59:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Procedure [dbo].[SP_UICreateNewUser]
(
     @UserName varchar(30),
     @EmailID varchar(100),
     @PrivilegeID int,
     @UserStatusID int,
     @UserPassword varchar(100),
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

	set @ErrorDescription = 'Inactive user cannot change information for other users'
	set @ResultFlag = 1
	return

End

---------------------------------------------------------
-- Make sure that the logged in user has higher or equal
-- privilege to the new user being created inthe system
---------------------------------------------------------

if ( ( @PrivilegeID = 1) and ( @LoggedUserPrivilegeID <> 1 ) )
Begin

	set @ErrorDescription = 'Non Admin user cannot create user with Admin rights'
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

Exec SP_UICheckUserPrivilegeRole @UserID , 'Create New User' , @ReturnFlag output

if (@ReturnFlag = 0)
Begin

	set @ErrorDescription = 'Logged User does not have privilege to create new users'
	set @ResultFlag = 1
	return

End


------------------------------------------------------------
-- VALIDATION 2: Check if the passed status and privilege
-- IDs are valid values
------------------------------------------------------------


if not exists ( select 1 from tb_userstatus where userstatusid = @UserStatusID )                    
Begin

	set @ErrorDescription = 'Invalid UserStatusID passed for creating new user'
	set @ResultFlag = 1
	return

End

if not exists ( select 1 from tb_userprivilege where userprivilegeid = @PrivilegeID )                    
Begin

	set @ErrorDescription = 'Invalid PrivilegeID passed for creating new user'
	set @ResultFlag = 1
	return

End

if ( @PrivilegeID = -1 )                    
Begin

	set @ErrorDescription = 'Cannot create user with super admin privileges. Please select any other privilege.'
	set @ResultFlag = 1
	return

End

--------------------------------
-- Update the user information
--------------------------------

Begin Try

	insert into tb_users ( name , EmailID , Password , UserPrivilegeId , UserStatusID , LoginAttempts , LastPasswordDate)
	values ( @UserName , @EmailID , HASHBYTES('MD5' , @UserPassword) , @PrivilegeID , @UserStatusID, 0 , convert(date , getdate()) )

End Try

Begin Catch

	set @ErrorDescription = ERROR_MESSAGE()
	set @ResultFlag = 1
	return

End Catch

Return
GO
