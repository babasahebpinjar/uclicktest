USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIUpdateCustomValidation]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_UIUpdateCustomValidation]
(
     @ValidationRuleID int,
     @ReferenceID int,
     @RuleName varchar(1000),
     @RuleSequence int,
     @ValidationStatusID int,
     @ActionScript varchar(2000),
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

Exec SP_UICheckUserPrivilegeRole @UserID , 'Edit Custom Business Rules' , @ReturnFlag output

if (@ReturnFlag = 0)
Begin

	set @ErrorDescription = 'Logged User does not have privilege to edit business rule'
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

---------------------------------------------------------------------------
-- VALIDATION 3: Check if the passed Reference exists in the system or not
---------------------------------------------------------------------------


if not exists ( select 1 from tb_vendorreferencedetails where referenceid = @ReferenceID )                    
Begin

	set @ErrorDescription = 'The reference does not exist in the system. Please check again.'
	set @ResultFlag = 1
	return

End


-----------------------------------------------------------------
-- VALIDATION 4: Check if the passed status IDs are valid values
-----------------------------------------------------------------


if not exists ( select 1 from tb_validationstatus where ValidationStatusID = @ValidationStatusID )                    
Begin

	set @ErrorDescription = 'Invalid custom validation rule status passed while editing business rule'
	set @ResultFlag = 1
	return

End


----------------------------------------------------------------------------------
-- VALIDATION 5: Check that rule sequence is a valid greater than 0 numerical value
----------------------------------------------------------------------------------

if ( (isnumeric( @RuleSequence ) = 0 ) or (@RuleSequence <= 0) )                
Begin

	set @ErrorDescription = 'Rule sequence is either not numeric or is less than equal to 0. Please enter a postive number'
	set @ResultFlag = 1
	return

End

----------------------------------------------------------------------------------
-- VALIDATION 6: Check that the action script is indeed a valid SQL script
----------------------------------------------------------------------------------

create table #TempVendorOfferData
(
	Destination varchar(500),
	DialedDigit varchar(60),
	EffectiveDateStr varchar(20),
	Rate varchar(25),
	BusinessIndicator varchar(1000),
	CountryCode varchar(20),
    ErrorMessage varchar(2000),
    ErrorCode varchar(20),
    EffectiveDate DateTime,
	RatingMethod varchar(60),
	RateBand varchar(60),
	RateTypeID int
)

Declare @VarActionScript varchar(2000)

set @VarActionScript = @ActionScript


Begin Try

	--------------------------------------------------------
	-- Replace default variables with their respective values
	---------------------------------------------------------

	set @VarActionScript = replace(@VarActionScript , '@OfferDate' , '''' + convert(varchar(10) ,Getdate() , 120) + '''')

	Exec (@VarActionScript)

End Try

Begin Catch

	set @ErrorDescription = 'Action script is syntactically not correct.'+char(10)+' Error message : ( ' + ERROR_MESSAGE() + ' )'
	set @ResultFlag = 1

	drop table #TempVendorOfferData

	return

End Catch


drop table #TempVendorOfferData

-----------------------------------------------------------------
-- VALIDATION 7: Check that the schema name in the DML should be
-- #TempVendorOfferData
-----------------------------------------------------------------

if ( charindex( '#TempVendorOfferData', @ActionScript) = 0 )
     
Begin

	set @ErrorDescription = 'Action script is syntactically not correct. No reference to schema #TempVendorOfferData can be found in the script'
	set @ResultFlag = 1
	return

End

------------------------------------------
-- Update custom validation rule
------------------------------------------

Begin Try

        update tb_Validationrules
	set Rulename = @RuleName,
	    ReferenceID = @ReferenceID,
	    ruleSequence = @RuleSequence,
            ActionScript = @ActionScript,
            validationstatusid = @ValidationStatusID
	where ValidationRuleId = @ValidationRuleID


End Try

Begin Catch

	set @ErrorDescription = ERROR_MESSAGE()
	set @ResultFlag = 1
	return

End Catch

Return
GO
