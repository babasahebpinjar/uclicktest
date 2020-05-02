USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetApplicationSettingsDetails]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetApplicationSettingsDetails]
(
	@UserID int
)
--With Encryption
As


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
-- Make sure that the logged in user exists in system and is
-- not in an inactive state
-- This is to cover a corner scenario where logged in user
-- might have been deleted
-------------------------------------------------------------
 
if ( ( @LoggedUserStatusID is NULL ) or ( @LoggedUserStatusID = 2 ) )               
Begin

	select NULL as KeyName , NULL as Value
	return

End


---------------------------------------------------
--  Check if the session user has the essential
-- privilege to update the user information
---------------------------------------------------

Declare @ReturnFlag int

Exec SP_UICheckUserPrivilegeRole @UserID , 'Edit Application Settings' , @ReturnFlag output

if (@ReturnFlag = 0)
Begin

	select NULL as KeyName , NULL as Value
	return

End


-------------------------------------------
-- In case everything is okay, return the 
-- dataset to be displayd on UI
-------------------------------------------

select convert(varchar(100) , KeyName) as KeyName , convert(varchar(500) , Value) as Value
from tblAppSettings
where keyname not in
(
	'IncomingMailServerReadTimeOut',
	'Status',
	'GMTHours',
	'GMTMinutes',
	'SpamMailServiceInterval',
	'SendRejectionforNonVendorOfferMail',
	'CheckingAuthorizedMailFlag',
	'NumberOFMailToReadPerDay',
	'EmailUniqueIdsLogFilePath'
)



Return
GO
