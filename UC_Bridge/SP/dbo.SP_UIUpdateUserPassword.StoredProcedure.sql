USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIUpdateUserPassword]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIUpdateUserPassword]
(
     @OldPassword varchar(100) = NULL,
     @NewPassword varchar(100),
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

	set @ErrorDescription = 'Inactive user cannot change information for other users'
	set @ResultFlag = 1
	return

End

---------------------------------------------------------
-- Make sure that the logged in user has higher or equal
-- privilege to the EDIT user
---------------------------------------------------------

if ( ( @EditUserPrivilegeID = 1) and ( @LoggedUserPrivilegeID <> 1 ) )
Begin

	set @ErrorDescription = 'Non Admin user cannot change user information for user with Admin rights'
	set @ResultFlag = 1
	return

End

--------------------------------------------------------
-- A non Admin user can only change his password. 
--------------------------------------------------------

if ( ( @LoggedUserPrivilegeID <> 1 ) and ( @EditUserID <> @UserID))
Begin

	set @ErrorDescription = 'Non Admin user can only change their password and not for any other user'
	set @ResultFlag = 1
	return

End



-----------------------------------------------
-- Perform essential validations on all the 
-- input parameters before proceeding with
-- update
-----------------------------------------------

------------------------------------------------------------
-- VALIDATION 1: Check if the old password is NULL. This is
-- allowed only in the scenario where the logged user has
-- ADMIN privileges
------------------------------------------------------------

if ( @OldPassword is NULL )
Begin

      if not exists ( select 1 from tb_users where userid = @UserID and userstatusid = 1 and userprivilegeid = 1 )                    
      Begin

		set @ErrorDescription = 'Old password cannot be empty.Logged user does not have Admin rights'
		set @ResultFlag = 1
		return

      End

End

if ( (@LoggedUserPrivilegeID <> 1) and ( HASHBYTES('MD5' , @OldPassword) <> @EditUserPassword ) )
Begin

	set @ErrorDescription = 'Old password provided does not match entry in system'
	set @ResultFlag = 1
	return

End


------------------------------------------------------------
-- VALIDATION 2: Check if the old password and the new
-- password are the same
------------------------------------------------------------

if ( HASHBYTES('MD5' , @OldPassword) = HASHBYTES('MD5' , @NewPassword) )
Begin

	set @ErrorDescription = 'Old and New password are the same.Please provide different value for New Password'
	set @ResultFlag = 1
	return


End


if exists ( select 1 from tb_UsersPasswordList where userid = @EditUserID and password = HASHBYTES('MD5' , isnull(@NewPassword, '')))
Begin

	set @ErrorDescription = 'New password provided cannot be same as previously used old passoword'
	set @ResultFlag = 1
	return

End

--------------------------------
-- Update the user information
--------------------------------

Begin Try

	update tb_users
	set  Password = HASHBYTES('MD5' , @NewPassword),
	     LastPasswordDate = convert(date , getdate())
	where UserID = @EditUserID

	---------------------------------------------------------
	-- Insert an entry into the user passwor list table to
	-- keep record of all used passwords
	---------------------------------------------------------


	insert into tb_userspasswordlist (userid , password) values (@EditUserID , @EditUserPassword )



End Try

Begin Catch

	set @ErrorDescription = ERROR_MESSAGE()
	set @ResultFlag = 1
	return

End Catch

Return
GO
