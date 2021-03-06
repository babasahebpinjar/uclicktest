USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICreateNewExceptionCheck]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UICreateNewExceptionCheck] 
(
    @ReferenceID		int,
    @EmailAddress		varchar(300),
    @Subject			varchar(500),
    @OfferTypeID		int,
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

Exec SP_UICheckUserPrivilegeRole @UserID , 'Create New Exception Check' , @ReturnFlag output

if (@ReturnFlag = 0)
Begin

	set @ErrorDescription = 'Logged User does not have privilege to create new Exception Check'
	set @ResultFlag = 1
	return

End


---------------------------
-- REFERENCE ID
---------------------------

if ( (@ReferenceID is NULL) or not exists ( select 1 from TB_VendorReferenceDetails where ReferenceID = @ReferenceID))
Begin

	set @ErrorDescription = 'The Reference for which Exeption Check is requested does not exist or passed ID value is NULL'
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



----------------------------------------------------------
-- Check if a similiar entry already exists in the system
----------------------------------------------------------

if exists ( 
		select 1 from tblVendorEmailDetails 
		where referenceid = @ReferenceID 
		and emailaddress = @EmailAddress
		and Subject = @Subject
		and offertypeid = @OfferTypeID
	 )
Begin

	set @ErrorDescription = 'Duplicate Entry. There already exists an entry for the reference , offertype , email address and subject combination'
	set @ResultFlag = 1
	return

End



Declare	@Account varchar(60),
	@ResultFlag2 int,
	@ErrorDescription2 varchar(2000)

select @Account = account
from tb_vendorreferencedetails
where referenceid = @ReferenceID


-------------------------------------------------
-- Perform the update post all the validations
-------------------------------------------------

Begin Tran

		Begin Try

			if not exists ( select 1 from tblAuthorizedEmails where referenceid = @ReferenceID and EmailAddress = @EmailAddress )
			Begin
					
					-------------------------------------------------------------------
					-- Create a new Authorized Sender Check for the new email address
					-------------------------------------------------------------------

					set @ResultFlag2 = 0

					Exec SP_UICreateNewAuthorizedEmailCheck  @Account , @Account , @EmailAddress , @ReferenceID , @UserID, @ResultFlag2 output , @ErrorDescription2 output

					if ( @ResultFlag2 = 1 )
					Begin

						set @ResultFlag = 1
						set @ErrorDescription = @ErrorDescription2
						Goto ENDPROC

					End



			End

			Insert into  tblVendorEmailDetails
			(ReferenceID , EmailAddress , OfferTypeID , Subject , CreatedDate )
			Values
			(@ReferenceID , @EmailAddress , @OfferTypeID , @Subject , GetDate() )
			
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
