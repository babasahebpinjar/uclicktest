USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIUpdateUserDetails]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIUpdateUserDetails]
(
     @UserName varchar(30),
     @EmailID varchar(100),
     @PrivilegeID int,
     @UserStatusID int,
     @OldPassword varchar(100) = NULL,
     @NewPassword varchar(100) = NULL,
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


-----------------------------------------------
-- Perform essential validations on all the 
-- input parameters before proceeding with
-- update
-----------------------------------------------

------------------------------------------------------------
-- VALIDATION 1: Check if the session user has the essential
-- privilege to update the user information
------------------------------------------------------------

Declare @ReturnFlag int

Exec SP_UICheckUserPrivilegeRole @UserID , 'Edit All Users' , @ReturnFlag output

if (@ReturnFlag = 0)
Begin

	set @ErrorDescription = 'Logged User does not have privilege to modify user details'
	set @ResultFlag = 1
	return

End


----------------------------------------------------
-- Make sure that if empty string are passed in the
-- old and new passwords, then the same need to be
-- set to NULL
----------------------------------------------------

if (( @OldPassword is not NULL) and (len(@OldPassword) = 0))
Begin

	set @OldPassword = NULL

End

if (( @NewPassword is not NULL) and (len(@NewPassword) = 0))
Begin

	set @NewPassword = NULL

End




------------------------------------------------------------
-- VALIDATION 2: Check if the old password is NULL. This is
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

if ( (@LoggedUserPrivilegeID <> 1) and ( HASHBYTES('MD5' , isnull(@OldPassword, '')) <> @EditUserPassword ) )
Begin

	set @ErrorDescription = 'Old password provided does not match entry in system'
	set @ResultFlag = 1
	return

End


if ( ( @NewPassword is not NULL) and ( HASHBYTES('MD5' , isnull(@NewPassword, '')) = @EditUserPassword ) )
Begin

	set @ErrorDescription = 'New password provided cannot be same as the old passoword'
	set @ResultFlag = 1
	return

End

if ( ( @NewPassword is not NULL) and  exists ( select 1 from tb_UsersPasswordList where userid = @EditUserID and password = HASHBYTES('MD5' , isnull(@NewPassword, '')) ))
Begin

	set @ErrorDescription = 'New password provided cannot be same as previously used old passoword'
	set @ResultFlag = 1
	return

End

------------------------------------------------------------
-- VALIDATION 3: Check if the passed status and privilege
-- IDs are valid values
------------------------------------------------------------


if not exists ( select 1 from tb_userstatus where userstatusid = @UserStatusID )                    
Begin

	set @ErrorDescription = 'Invalid UserStatusID passed for updating user information'
	set @ResultFlag = 1
	return

End

if not exists ( select 1 from tb_userprivilege where userprivilegeid = @PrivilegeID )                    
Begin

	set @ErrorDescription = 'Invalid PrivilegeID passed for updating user information'
	set @ResultFlag = 1
	return

End



-----------------------------------------------------------
-- Added section on 18th Nov 2013
-- Before updating the user details, check to ensure that
-- the old password of the user has not crossed the aging
-- period. Incase it has crossed the aging period, then 
-- the user should be prompted that passwor needs to be 
-- changed when updating the user details.
------------------------------------------------------------

Declare @PasswordAgingDays int,
        @LastPasswordDate date

select @PasswordAgingDays = configValue
from tb_config
where ConfigName = 'PasswordAgingDays'

set @PasswordAgingDays = isnull(@PasswordAgingDays , 999)


Select  @LastPasswordDate = LastPasswordDate
from tb_users
where userid = @EditUserID

if ( ( datediff(dd , @LastPasswordDate ,  convert(date , getdate())) > @PasswordAgingDays) and @NewPassword is NULL )
Begin

	set @ErrorDescription = 'User password has expired and has passed the aging period. Please update the user with a new password'
	set @ResultFlag = 1
	return

End

--------------------------------
-- Update the user information
--------------------------------

Begin Try

	update tb_users
	set Name = @UserName ,
	    EmailID = @EmailID ,
	    Password = 
                     Case
                         when @NewPassword is not null then HASHBYTES('MD5' , @NewPassword)
                         else password
                     End,
	    UserPrivilegeID = @PrivilegeID,
	    UserStatusID = @UserStatusID,
	    LastPasswordDate = 
                     Case
                         when @NewPassword is not null then convert(date , getdate())
                         else LastPasswordDate
                     End
	where UserID = @EditUserID

	---------------------------------------------------------
	-- Insert an entry into the user passwor list table to
	-- keep record of all used passwords
	---------------------------------------------------------

	if ( @NewPassword is not null )
	Begin

		insert into tb_userspasswordlist (userid , password) values (@EditUserID , @EditUserPassword )

	End


End Try

Begin Catch

	set @ErrorDescription = ERROR_MESSAGE()
	set @ResultFlag = 1
	return

End Catch

Return
GO
