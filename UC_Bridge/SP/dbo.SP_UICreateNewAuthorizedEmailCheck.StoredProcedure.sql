USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICreateNewAuthorizedEmailCheck]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UICreateNewAuthorizedEmailCheck] 
(
    @Name			varchar(100),
    @Company			varchar(200),
    @EmailAddress		varchar(300),
    @ReferenceID		int,
    @UserID                     int,
    @ResultFlag			int Output,
    @ErrorDescription		varchar(500) Output
)
--With Encryption
As


set @ResultFlag	= 0

------------------------------------------------------------
--  Check if the session user has the essential
-- privilege to Create new Authorized Sender check
------------------------------------------------------------

Declare @ReturnFlag int

Exec SP_UICheckUserPrivilegeRole @UserID , 'Create New Authorized Email Check' , @ReturnFlag output

if (@ReturnFlag = 0)
Begin

	set @ErrorDescription = 'Logged User does not have privilege to create new Authorized Sender Check'
	set @ResultFlag = 1
	return

End


---------------------------
-- REFERENCE ID
---------------------------

if ( (@ReferenceID is NULL) or not exists ( select 1 from TB_VendorReferenceDetails where ReferenceID = @ReferenceID))
Begin

	set @ErrorDescription = 'The Reference for which authorized Sender Check is requested does not exist or passed ID value is NULL'
	set @ResultFlag = 1
	return

End

-----------
-- NAME
-----------

if ( @Name is NULL )
Begin


	set @ErrorDescription = 'Name for the Authorized Sender Check cannot be empty or NULL'
	set @ResultFlag = 1
	return

 

End


-------------
-- COMPANY
-------------

if ( @Company is NULL )
Begin


	set @ErrorDescription = 'Company for the Authorized Sender Check cannot be empty or NULL'
	set @ResultFlag = 1
	return

 

End


-------------------
-- EMAIL ADDRESS
-------------------

if ( ( @EmailAddress is null ) or ( dbo.fn_ValidateEmailAddress(@EmailAddress) = 1 ) )
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Email ID provided is NULL or not a valid email address'
	return


End


-----------------------------------------------------------
-- Check to ensure that an entry does not exist already for
-- the combination of email and Reference
-----------------------------------------------------------

if exists ( select 1 from tblAuthorizedEmails where ReferenceID = @ReferenceID and emailaddress = @EmailAddress)
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Authorized Sender Check already exists for the reference and email address combination. Please provide different values'
	return


End

-------------------------------------------------
-- Perform the update post all the validations
-------------------------------------------------

Begin Try

	Insert into  tblAuthorizedEmails
	(Name , EmailAddress , Company , ReferenceID , CreatedDate )
	Values
	(@Name , @EmailAddress , @Company , @ReferenceID , GetDate() )
	
End Try


Begin Catch

	set @ResultFlag = 1
	set @ErrorDescription = ERROR_MESSAGE()
	return

End Catch
GO
