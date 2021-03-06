USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIUpdateExceptionCheckDetails]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIUpdateExceptionCheckDetails] 
(
    @ExceptionCheckID		int,
    @EmailAddress		varchar(300),
    @Subject                    varchar(1000) = NULL,
    @OfferTypeID                int,
    @UserID                     int,
    @ResultFlag			int Output,
    @ErrorDescription		varchar(500) Output
)
--With Encryption
As

set @ResultFlag	 = 0

------------------------------------------------------------
--  Check if the session user has the essential
-- privilege to update the Authorized Sender information
------------------------------------------------------------

Declare @ReturnFlag int

Exec SP_UICheckUserPrivilegeRole @UserID , 'Edit Exception Check' , @ReturnFlag output

if (@ReturnFlag = 0)
Begin

	set @ErrorDescription = 'Logged User does not have privilege to modify Exception Check Details'
	set @ResultFlag = 1
	return

End


---------------------------
-- EXCEPTION CHECK ID
---------------------------

if ( (@ExceptionCheckID is NULL) or not exists ( select 1 from tblVendorEmailDetails where ID = @ExceptionCheckID))
Begin

	set @ErrorDescription = 'The Exception Check requested for update does not exist or passed ID value is NULL'
	set @ResultFlag = 1
	return

End


-------------------
-- OFFER TYPE ID
-------------------

if ( @OfferTypeID is NULL )
Begin


	set @ErrorDescription = 'Offer Type for the Exception Check cannot be empty or NULL. Valid Values are (AZ/FC/PR)'
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


------------
-- SUBJECT 
------------

if ( @Subject is NULL )
Begin


	set @ErrorDescription = 'Email Subject for the Exception Check cannot be empty or NULL.'
	set @ResultFlag = 1
	return

 

End

if ( ( @Subject is not null ) and ( len(@Subject) = 0) )
Begin

	set @ErrorDescription = 'Email Subject for the Exception Check cannot be empty.'
	set @ResultFlag = 1
	return


End



------------------------------------------
-- Get all the old details for the 
-- Exception check
------------------------------------------

Declare @OldReferenceID int,
        @OldEmailAddress varchar(300),
	@AuthorizedSendersID int,
	@Name varchar(100),
	@Company varchar(200),
	@Account varchar(60),
	@ResultFlag2 int,
	@ErrorDescription2 varchar(2000)

select @OldReferenceID = ReferenceID,
       @OldEmailAddress = EmailAddress
from tblVendorEmailDetails
where ID = @ExceptionCheckID

select @Account = account
from tb_vendorreferencedetails
where referenceid = @OldReferenceID


----------------------------------------------------------
-- Check if a similiar entry already exists in the system
----------------------------------------------------------

if exists ( 
		select 1 from tblVendorEmailDetails 
		where referenceid = @OldReferenceID 
		and emailaddress = @EmailAddress
		and Subject = @Subject
		and offertypeid = @OfferTypeID
		and ID <> @ExceptionCheckID
	 )
Begin

	set @ErrorDescription = 'Duplicate Entry. There already exists an entry for the reference , offertype , email address and subject combination'
	set @ResultFlag = 1
	return

End
	
-------------------------------------------------
-- Perform the update post all the validations
-------------------------------------------------

Begin Tran

		Begin Try


			----------------------------------------------------------
			-- Check if there exists an authorized sender check for
			-- the old email address and reference id or not. Incase
			-- the same eists, one needs to check if there exists an
			-- authorized sender check for new email address and
			-- reference id and then take desired action
			----------------------------------------------------------

			if ( @OldEmailAddress <> @EmailAddress )
			Begin

				if exists ( select 1 from tblAuthorizedEmails where referenceid = @OldReferenceID and EmailAddress = @OldEmailAddress )
				Begin

					select @AuthorizedSendersID = ID,
					       @Name = name,
					       @Company = Company
					from tblAuthorizedEmails
					where referenceid = @OldReferenceID 
					and EmailAddress = @OldEmailAddress


					if exists ( select 1 from tblAuthorizedEmails where referenceid = @OldReferenceID and EmailAddress = @EmailAddress )
					Begin
							
							-------------------------------------------------------------------
							-- Delete the old email address details from the Authorized Sender
							-- Check
							-------------------------------------------------------------------

							set @ResultFlag2 = 0

							Exec SP_UIDeleteAuthorizedSenderDetails @AuthorizedSendersID , @UserID, @ResultFlag2 output , @ErrorDescription2 output

							if ( @ResultFlag2 = 1 )
							Begin

								set @ResultFlag = 1
								set @ErrorDescription = @ErrorDescription2
								Goto ENDPROC

							End



					End

					Else
					Begin

							-------------------------------------------------------------------
							-- Update the new email address details in the existing Authorized
							-- Senders Check
							-------------------------------------------------------------------

							set @ResultFlag2 = 0

							Exec SP_UIUpdateAuthorizedSenderDetails  @AuthorizedSendersID , @Name , @Company , @EmailAddress , @UserID, @ResultFlag2 output , @ErrorDescription2 output

							if ( @ResultFlag2 = 1 )
							Begin

								set @ResultFlag = 1
								set @ErrorDescription = @ErrorDescription2
								Goto ENDPROC

							End


					End
				


				End

				Else
				Begin

					if not exists ( select 1 from tblAuthorizedEmails where referenceid = @OldReferenceID and EmailAddress = @EmailAddress )
					Begin
							
							-------------------------------------------------------------------
							-- Create a new Authorized Sender Check for the new email address
							-------------------------------------------------------------------

							set @ResultFlag2 = 0

							Exec SP_UICreateNewAuthorizedEmailCheck  @Account , @Account , @EmailAddress , @OldReferenceID , @UserID, @ResultFlag2 output , @ErrorDescription2 output

							if ( @ResultFlag2 = 1 )
							Begin

								set @ResultFlag = 1
								set @ErrorDescription = @ErrorDescription2
								Goto ENDPROC

							End



					End

				  End

			End

			----------------------------------------------------------
			-- Update the Exception Check details with the new data
			-- post creation of the authorized senders check
			----------------------------------------------------------

			update tblVendorEmailDetails
			set OfferTypeID = @OfferTypeID,
			    Subject = @Subject,
			    EmailAddress = @EmailAddress,
			    UpdatedDate = getdate()
			where ID = @ExceptionCheckID


		End Try


		Begin Catch

			set @ResultFlag = 1
			set @ErrorDescription = ERROR_MESSAGE()
			Rollback Tran
			Goto ENDPROC

		End Catch

Commit Tran

ENDPROC:

Return
GO
