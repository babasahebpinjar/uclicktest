USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIUpdateAuthorizedSenderDetails]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIUpdateAuthorizedSenderDetails] 
(
    @AuthorizedSenderID		int,
    @Name			varchar(100),
    @Company			varchar(200),
    @EmailAddress		varchar(300),
    @UserID                     int,
    @ResultFlag			int Output,
    @ErrorDescription		varchar(500) Output
)
--With Encryption
As

set @ResultFlag = 0

------------------------------------------------------------
--  Check if the session user has the essential
-- privilege to update the Authorized Sender information
------------------------------------------------------------

Declare @ReturnFlag int

Exec SP_UICheckUserPrivilegeRole @UserID , 'Edit Authorized Email Check' , @ReturnFlag output

if (@ReturnFlag = 0)
Begin

	set @ErrorDescription = 'Logged User does not have privilege to modify Authorized Sender Details'
	set @ResultFlag = 1
	return

End


---------------------------
-- AUTHORIZED SENDER ID
---------------------------

if ( (@AuthorizedSenderID is NULL) or not exists ( select 1 from tblAuthorizedEmails where ID = @AuthorizedSenderID))
Begin

	set @ErrorDescription = 'The Authorized Email Check requested for update does not exist or passed ID value is NULL'
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


------------------------------------------------------------------------
-- It is essential that when one is updating the EMAIL ADDRESS in the
-- Authorized Sender, then t should be checked that there does not exist
-- an EMAIL CHECK on the old email address. If it does then the system 
-- should intimate the user to not UPDATE, but create a new AUTHORIED
-- SENDER check
-------------------------------------------------------------------------

Declare @OldEmailAddress varchar(300),
        @ReferenceID int

Select @OldEmailAddress = EmailAddress,
       @ReferenceID = ReferenceID
from tblAuthorizedEmails
where ID = @AuthorizedSenderID

if (@OldEmailAddress  <> @EmailAddress )
Begin

	if exists ( select 1 from tblVendorEmailDetails where referenceID = @ReferenceID  and EmailAddress = @OldEmailAddress )
	Begin

		set @ResultFlag = 1
		set @ErrorDescription = 'Cannot update the email address for the Authorized Sender Check. There exists an Exception check on old email address:('+@OldEmailAddress +').'+
				' Please create a new Authorized Sender Check for :(' + @EmailAddress + ')'
		return
	

	End

End

-------------------------------------------------
-- Perform the update post all the validations
-------------------------------------------------

Begin Try

	update tblAuthorizedEmails
	set Name = @Name,
	    EmailAddress = @EmailAddress,
	    Company = @Company,
            UpdatedDate = GetDate()
	where ID = @AuthorizedSenderID


End Try


Begin Catch

	set @ResultFlag = 1
	set @ErrorDescription = ERROR_MESSAGE()
	return

End Catch
GO
