USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIValidateUserCredentials]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_UIValidateUserCredentials]
(
	@EmailId varchar(100),
	@Password varchar(15),
	@UserID int = Null Output ,
	@NameOfUser varchar(100) = Null Output ,
	@UserPrivilegeID int = NULL Output,
	@UserLoginStatusFlag int Output 
	       -- 0 ( user exists and login passed or failed ) , 1 ( User exists but inactive ) , 2 ( User does not exists in system ) , 3 ( User exists but inactivated )
)
--With Encryption
As


Declare @UserStatusID int = 0,
        @MaxLoginAttempts int,
	@LoginAttempts int = 0,
	@PasswordAgingDays int,
	@LastPasswordDate date

	
set @UserLoginStatusFlag = 0

select @MaxLoginAttempts = configValue
from tb_config
where ConfigName = 'MaxLoginAttempts'

select @PasswordAgingDays = configValue
from tb_config
where ConfigName = 'PasswordAgingDays'

set @MaxLoginAttempts = isnull(@MaxLoginAttempts , 99)

set @PasswordAgingDays = isnull(@PasswordAgingDays , 999)

-------------------------------------------------
-- Check if the email id passed to the system
-- exists or not
-------------------------------------------------

if exists (select 1 from tb_users where EmailID = @EmailId)
Begin

	-------------------------------------------------
	-- Check if this is an Active or InActive User
	-------------------------------------------------

	Select @UserStatusID =  UserStatusID from tb_users where EmailID = @EmailId

	if ( @UserStatusID = 1 )
	Begin

	       ----------------------------------------------------------------------
	       -- Check if the password credentials are correct.Incase it is
	       -- not correct, increment the login attempt field by 1.
	       -- In case the number of login attempts is more than the configured
	       -- value, use needs to be inactivated
	       ----------------------------------------------------------------------

	       if exists ( select 1 from tb_users where EmailID = @EmailId and password = HASHBYTES('MD5' , @Password) and UserStatusID = 1)
	       Begin

			--------------------------------------------------
			-- Reset the number of login attempts to 0 post 
			-- successful login
			--------------------------------------------------

			update tb_users
			set LoginAttempts = 0
			where EmailID = @EmailId

			Select @UserID = UserID,
				   @NameOfUser = Name,
				   @UserPrivilegeID = userprivilegeID,
				   @LastPasswordDate = LastPasswordDate
			from tb_users
			where EmailID = @EmailId
			and password = HASHBYTES('MD5' , @Password)	 
			and UserStatusID = 1

			--------------------------------------------------
			-- User login is successful and now it needs to be
			-- checked if the password for the user has passed 
			-- the aging period or not
			--------------------------------------------------

			if ( datediff(dd , @LastPasswordDate ,  convert(date , getdate())) > @PasswordAgingDays)
			Begin

                                ---------------------------------------------------------------
				-- User will be inactivated and a message will be prompted that
				-- his password has expired. The user now needs to be activated 
				-- and a new password needs to be provided
				----------------------------------------------------------------

				update tb_users
				set UserStatusID = 2
				where EmailID = @EmailId
				and password = HASHBYTES('MD5' , @Password)	 
				and UserStatusID = 1

				set @UserLoginStatusFlag = 4 
				set @NameOfUser = NULL
				set @UserPrivilegeID = NULL
				set @UserID = NULL

			End
			
                        Else
			Begin

			       -------------------------------------------------------------------
			       -- if the difference between last password change and current date
			       -- is lesser from password aging days by 5 days, then flag needs to
			       -- be set as 5
			       -------------------------------------------------------------------

				if ( @PasswordAgingDays - datediff(dd , @LastPasswordDate ,  convert(date , getdate())) <= 5 )
				Begin

					set @UserLoginStatusFlag = 5

				End

				Else
				Begin

					set @UserLoginStatusFlag = 0

				End

			End


	       End

	       Else
	       Begin

	                -----------------------------------------------------
			-- Increase the failed attempt count by 1 in case of
			-- failure
			-----------------------------------------------------

			update tb_users
			set LoginAttempts = isnull(LoginAttempts , 0) + 1
			where EmailID = @EmailId

			Select @LoginAttempts = LoginAttempts
			from tb_users
			where EmailID = @EmailId


                        ------------------------------------------------------
			-- If the number of failed login attempts are more than
			-- the configured value, then inactivate the account
			------------------------------------------------------

			if (@LoginAttempts > @MaxLoginAttempts)
			Begin

				update tb_users
				set UserStatusID = 2,
				    LoginAttempts = 0
				where EmailID = @EmailId

				set @UserLoginStatusFlag = 3

			End

			Else
			Begin

				set @UserLoginStatusFlag = 0

			End


			set @NameOfUser = NULL
			set @UserPrivilegeID = NULL
			set @UserID = NULL


	       End


	End

        --------------------------------------------------
	-- User exists in the system, but is INACTIVE
	--------------------------------------------------

	Else
	Begin

		set @UserLoginStatusFlag = 1
		set @NameOfUser = NULL
		set @UserPrivilegeID = NULL
		set @UserID = NULL

	End

End

-----------------------------------------------------
-- The passed EMAIL ID does not exists in the system
-----------------------------------------------------

Else
Begin

	set @UserLoginStatusFlag = 2
	set @NameOfUser = NULL
	set @UserPrivilegeID = NULL
	set @UserID = NULL

End


Return  
	   

	
GO
