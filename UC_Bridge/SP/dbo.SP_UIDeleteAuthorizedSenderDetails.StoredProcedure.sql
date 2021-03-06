USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIDeleteAuthorizedSenderDetails]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIDeleteAuthorizedSenderDetails] 
(
    @AuthorizedSenderID		int,
    @UserID                     int,
    @ResultFlag			int Output,
    @ErrorDescription		varchar(500) Output
)
--With Encryption
As

set @ResultFlag	 = 0

------------------------------------------------------------
--  Check if the session user has the essential
-- privilege to delete the Authorized Sender information
------------------------------------------------------------

Declare @ReturnFlag int

Exec SP_UICheckUserPrivilegeRole @UserID , 'Delete Authorized Email Check' , @ReturnFlag output

if (@ReturnFlag = 0)
Begin

	set @ErrorDescription = 'Logged User does not have privilege to delete Authorized Sender Details'
	set @ResultFlag = 1
	return

End

if ( (@AuthorizedSenderID is NULL) or not exists ( select 1 from tblAuthorizedEmails where ID = @AuthorizedSenderID))
Begin

	set @ErrorDescription = 'The Authorized Email Check requested for Deletion does not exist or passed ID value is NULL'
	set @ResultFlag = 1
	return

End

-------------------------------------------------
-- Get the Reference and Email details for the
-- authorized sender check
-------------------------------------------------

Declare @ReferenceID int,
        @EmailAddress varchar(300)

select @ReferenceID = Referenceid,
       @EmailAddress = EmailAddress
from tblAuthorizedEmails
where id = @AuthorizedSenderID

----------------------------------------------------------------
-- Check if the Email Check for the reference is ON and this is 
-- the only authorized sender entry
----------------------------------------------------------------
Declare @AuthorizedSenderCount int = 0

if exists ( select 1 from tb_vendorReferenceDetails where ReferenceID = @ReferenceID and EnableEmailCheck = 1 )
Begin

	select @AuthorizedSenderCount = count(*)
	from tblAuthorizedEmails
	where referenceid = @ReferenceID 


	if ( @AuthorizedSenderCount = 1 )
	Begin

		set @ErrorDescription = 'Not Allowed to delete the only Authorized Sender Details when the Reference has the Email Check Turned ON'
		set @ResultFlag = 1
		return

	End

End

Begin Try

        ------------------------------------------------------------
	-- Check if there exists an entry in the Excpetion Check
	-- for this email address and reference. Thi also needs to
	-- be deleted from the system
	------------------------------------------------------------

	if exists ( select 1 from tblvendoremaildetails where referenceid = @ReferenceID and EmailAddress = @EmailAddress )
	Begin
		Delete from tblvendoremaildetails
		where referenceid = @ReferenceID 
		and EmailAddress = @EmailAddress

	End

	Delete From tblAuthorizedEmails
	where ID = @AuthorizedSenderID


End Try


Begin Catch

	set @ResultFlag = 1
	set @ErrorDescription = ERROR_MESSAGE()
	return

End Catch
GO
