USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIDeleteUser]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIDeleteUser]
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

------------------------------------------------------------
-- Check if the session user has the essential privilege to 
-- update the user information
------------------------------------------------------------

Declare @ReturnFlag int

Exec SP_UICheckUserPrivilegeRole @UserID , 'Delete Users' , @ReturnFlag output

if (@ReturnFlag = 0)
Begin

	set @ErrorDescription = 'Logged User does not have privilege to delete users'
	set @ResultFlag = 1
	return

End


-----------------------------------------------------------------------------
-- Check to ensure that the user has not perfromed any Data Manipulation on 
-- any of the schema objects
-----------------------------------------------------------------------------

Declare @VarTableName varchar(200),
		@SQLStr nvarchar(max)

		
Declare Check_USer_Modified_Cur Cursor For
select tbl1.name
from sysobjects tbl1
inner join syscolumns tbl2 on tbl1.id = tbl2.id
where tbl2.name = 'ModifiedByID'
and tbl1.xtype = 'U'

Open Check_USer_Modified_Cur
Fetch Next From Check_USer_Modified_Cur
Into @VarTableName

While @@FETCH_STATUS = 0
Begin


	set @SQLStr = 'select @cnt = count(*) from ' + @VarTableName + ' where modifiedByID = ' + convert(varchar(20) , @EditUserID )
	Declare @cnt int
	exec sp_executesql @SQLStr, N'@cnt int output', @cnt = @cnt output

	if ( @cnt > 0 )
	Begin

			set @ErrorDescription = 'Cannot delete user which has performed data manipulation. Need to maintain user record for audit purpose'
			set @ResultFlag = 1
			return

	End

	Fetch Next From Check_USer_Modified_Cur
	Into @VarTableName

End

Close Check_USer_Modified_Cur
Deallocate Check_USer_Modified_Cur


---------------------------------
-- Delete the user fron system
---------------------------------

Begin Try

	Delete from tb_UsersPasswordList
	where UserID = @EditUserID

	Delete from tb_Users
	where USerID = @EditUserID

	

End Try

Begin Catch

	set @ErrorDescription = ERROR_MESSAGE()
	set @ResultFlag = 1
	return

End Catch
GO
