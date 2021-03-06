USE [UC_Admin]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIPerformActionPrivilege]    Script Date: 5/2/2020 5:59:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[SP_UIPerformActionPrivilege]
(
	@SessionID varchar(200),
	@UserID int,
        @ResultFlag int Output,
        @ErrorDescription varchar(200) Output

)

AS



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

	set @ErrorDescription = 'Logged User does not have permissions to edit privilege profiles '
	set @ResultFlag = 1
	GOTO PROCESSEND

End

---------------------------------------------------------------
-- VALIDATION 2: Check if the session id passed exists or not
---------------------------------------------------------------

if not exists (select 1 from wTb_PrivilegeAccessRoles where sessionid = @SessionID )
Begin

	set @ErrorDescription = 'The Session ID passed to action procedure does not exist or is invalid '
	set @ResultFlag = 1
	GOTO PROCESSEND

End


--------------------------------------------------
-- Perform essential DML depending on the action
--------------------------------------------------

if exists ( select 1 from wTb_PrivilegeAccessRoles where sessionid = @SessionID and _Action = 'DELETE' )
Begin

		Begin Try

			Delete tbl1
			from Tb_PrivilegeAccessRoles tbl1
			inner join wTb_PrivilegeAccessRoles tbl2 on tbl1.userprivilegeid = tbl2.userprivilegeid and tbl1.AccessRolesId = tbl2.AccessrolesID
			where tbl2.sessionID = @SessionID

		End Try

		Begin Catch

			set @ErrorDescription = 'Error during deletion of access roles !!!!.' +  ERROR_MESSAGE()
			set @ResultFlag = 1


			GOTO PROCESSEND

		End Catch

End


if exists ( select 1 from wTb_PrivilegeAccessRoles where sessionid = @SessionID and _Action = 'ADD' )
Begin

		Begin Try

		        insert into Tb_PrivilegeAccessRoles ( userprivilegeid , accessrolesid )
			select userprivilegeid , AccessrolesID
			from wTb_PrivilegeAccessRoles
                        where sessionID = @SessionID

		End Try

		Begin Catch

			set @ErrorDescription = 'Error during addition of access roles !!!!.' +  ERROR_MESSAGE()
			set @ResultFlag = 1


			GOTO PROCESSEND

		End Catch

End

PROCESSEND:

-------------------------------------------------------
-- Once done, need to delete the entries from the
-- working tables
-------------------------------------------------------

delete from wTb_PrivilegeAccessRoles
where sessionID = @SessionID


Return


GO
