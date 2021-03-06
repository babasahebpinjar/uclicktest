USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIDeleteCustomValidation]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Procedure [dbo].[SP_UIDeleteCustomValidation]
(
     @ValidationRuleID int,
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


-----------------------------------------------
-- Perform essential validations on all the 
-- input parameters before proceeding with
-- update
-----------------------------------------------

------------------------------------------------------------
-- VALIDATION 1: Check if the session user has the essential
-- privilege to create new business rule
------------------------------------------------------------

Declare @ReturnFlag int

Exec SP_UICheckUserPrivilegeRole @UserID , 'Delete Custom Business Rules' , @ReturnFlag output

if (@ReturnFlag = 0)
Begin

	set @ErrorDescription = 'Logged User does not have privilege to delete business rule'
	set @ResultFlag = 1
	return

End

-----------------------------------------------------------------
-- VALIDATION 2: Check if the validation rule is valid or not
-----------------------------------------------------------------

if not exists ( select 1 from tb_validationrules where ValidationRuleID = @ValidationRuleID  )                    
Begin

	set @ErrorDescription = 'Invalid custom validation rule reference passed. The validation rule reference doesnot exist'
	set @ResultFlag = 1
	return

End


------------------------------------------
-- Delete custom validation rule
------------------------------------------

Begin Try

        delete from tb_Validationrules
	where ValidationRuleId = @ValidationRuleID


End Try

Begin Catch

	set @ErrorDescription = ERROR_MESSAGE()
	set @ResultFlag = 1
	return

End Catch

Return
GO
