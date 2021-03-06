USE [UC_Admin]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIDeleteUser]    Script Date: 5/2/2020 5:59:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Procedure [dbo].[SP_UIDeleteUser]
(
     @UserID int,
     @EditUserID int,
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


-----------------------------------------------------
-- Get all essential details of the Edited USER
-----------------------------------------------------

Declare @EditUserStatusID int,
        @EditUserPrivilegeID int,
        @EditUserPassword varbinary(100)
         

select @EditUserStatusID = UserStatusID,
       @EditUserPrivilegeID = UserPrivilegeID,
       @EditUserPassword  = password
from tb_users
where UserID = @EditUserID

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

	set @ErrorDescription = 'Inactive user cannot delete users from system'
	set @ResultFlag = 1
	return

End

-----------------------------------------------
-- Perform essential validations on all the 
-- input parameters before proceeding with
-- update
-----------------------------------------------

--------------------------------------------------------
-- A user with delete rights cannot delete himself
-- from the system
--------------------------------------------------------

if ( @EditUserID =  @UserID)
Begin

	set @ErrorDescription = 'A user cannot delete itself from the system.'
	set @ResultFlag = 1
	return

End

---------------------------------------------------------
-- Only the uClick Admin user can delete users from
-- the system
---------------------------------------------------------

if ( @UserID <> -1 )
Begin

	set @ErrorDescription = 'Only uClick Administrator user can delete users from the system'
	set @ResultFlag = 1
	return

End

-----------------------------------------------
-- Cannot delete default users from the system
-- All default users have userid < 0
-----------------------------------------------

if ( @EditUserID < 0 )
Begin

	set @ErrorDescription = 'Cannot delete default users from the system'
	set @ResultFlag = 1
	return

End

--------------------------------
-- Update the user information
--------------------------------

Begin Try

	delete from tb_users
	where UserID = @EditUserID


End Try

Begin Catch

	set @ErrorDescription = ERROR_MESSAGE()
	set @ResultFlag = 1
	return

End Catch

Return
GO
