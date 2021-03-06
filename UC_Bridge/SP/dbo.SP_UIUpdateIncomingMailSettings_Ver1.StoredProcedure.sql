USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIUpdateIncomingMailSettings_Ver1]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIUpdateIncomingMailSettings_Ver1] 
(
	@UserID				int,
	@LicenseKey			varchar(100),
	@ServerName			varchar(100),
	@AccountName			varchar(300),
	@Password			varchar(100),
	@ReceiveMailFolderName		varchar(100),
	@SpamFolderName			varchar(100),
	@SuccessMailFolderName		varchar(100),
	@RejectionMoveFolderName	varchar(100),
	@TobeProcessedFolderName        varchar(100),
	@ProcessedFolderName		varchar(100),
	@SentFolderName			varchar(100),
	@MailStartDate			Date,
	@ResultFlag			int Output,
	@ErrorDescription		Varchar(200) Output
	)
--With Encryption
As

Declare @cmd varchar(2000)

set @ResultFlag = 0
set @ErrorDescription = NULL
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

	set @ResultFlag = 1
	set @ErrorDescription = 'Non existant or inactive user cannot edit Incoming Email setting parameters'
	return

End


---------------------------------------------------
-- Check if the session user has the essential
-- privilege to update the user information
---------------------------------------------------

Declare @ReturnFlag int

Exec SP_UICheckUserPrivilegeRole @UserID , 'Edit Email Settings' , @ReturnFlag output

if (@ReturnFlag = 0)
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Logged user does not have privilege to edit Incoming Email setting parameters'
	return


End



--------------------------------------
-- Check configuration parameters are
-- not NULL
--------------------------------------

if ( @LicenseKey is NULL )
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Configuration parameter LicenseKey cannot be NULL'
	return


End


if ( @ServerName is NULL )
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Configuration parameter ServerName cannot be NULL'
	return


End

if ( @AccountName is NULL )
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Configuration parameter AccountName cannot be NULL'
	return


End

if ( @Password is NULL )
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Configuration parameter Password cannot be NULL'
	return


End


---------------------------------------------------
-- Check all the settings which hold Folder Path
---------------------------------------------------

----------------------------------
-- Receive Mail Folder Name
----------------------------------

if ( @ReceiveMailFolderName is NULL )
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Configuration parameter ReceiveMailFolderName cannot be NULL'
	return


End


----------------------------------
-- Spam Folder Name
----------------------------------

if ( @SpamFolderName is NULL )
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Configuration parameter SpamFolderName cannot be NULL'
	return


End



----------------------------------
-- Success Mail Folder Name
----------------------------------

if ( @SuccessMailFolderName is NULL )
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Configuration parameter SuccessMailFolderName cannot be NULL'
	return


End


----------------------------------
-- Rejection Move Folder Name
----------------------------------

if ( @RejectionMoveFolderName is NULL )
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Configuration parameter RejectionMoveFolderName cannot be NULL'
	return


End


----------------------------------
-- To be Processed Folder Name
----------------------------------

if ( @TobeProcessedFolderName is NULL )
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Configuration parameter TobeProcessedFolderName cannot be NULL'
	return


End


----------------------------------
-- Processed Folder Name
----------------------------------

if ( @ProcessedFolderName is NULL )
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Configuration parameter ProcessedFolderName cannot be NULL'
	return


End


----------------------------------
-- Sent Folder Name
----------------------------------

if ( @SentFolderName is NULL )
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Configuration parameter SentFolderName cannot be NULL'
	return


End


----------------------
-- Mail Start Date
---------------------

if ((@MailStartDate is NULL) or ( isDate(convert(varchar(20) , @MailStartDate)) = 0 ))
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Configuration Setting MailStartDate is NULL or not in a valid date format (mm/dd/yyyy)'
	return


End


--------------------------------------------------------------------
-- Check the connectivity to imap server using the credentials.
-- Also check that all the folders exist
--------------------------------------------------------------------

Declare @ListOfFolders varchar(2000) = @ReceiveMailFolderName + '|' + @SpamFolderName + '|' + @SuccessMailFolderName + '|' + 
                                       @RejectionMoveFolderName + '|' + @TobeProcessedFolderName + '|' + @ProcessedFolderName + '|' + @SentFolderName

Create table #TempOutput (DataCol varchar(500) )

insert into #TempOutput
Exec SP_CheckIMAPConnectivity @ServerName , @AccountName , @Password , @ListOfFolders


-----------------------------------------
-- Connectivity Credentials Check
-----------------------------------------

if not exists ( select 1 from #TempOutput where rtrim(ltrim(DataCol)) = 'Authentication successful' )
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Credentials for connecting to the IMAP server are not correct'
	drop table #TempOutput
	return

End

-----------------------------------------
-- ReceiveMailFolderName Check
-----------------------------------------


if not exists ( select 1 from #TempOutput where rtrim(ltrim(DataCol)) = 'Folder '+ @ReceiveMailFolderName +' exists' )
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Receive Mail Folder doesnot exist on IMAP Server. Please check the value'
	drop table #TempOutput
	return

End

-----------------------------------------
-- SpamFolderName Check
-----------------------------------------


if not exists ( select 1 from #TempOutput where rtrim(ltrim(DataCol)) = 'Folder '+ @SpamFolderName +' exists' )
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Spam Mail Folder doesnot exist on IMAP Server. Please check the value'
	drop table #TempOutput
	return

End

-----------------------------------------
-- SuccessMailFolderName Check
-----------------------------------------


if not exists ( select 1 from #TempOutput where rtrim(ltrim(DataCol)) = 'Folder '+ @SuccessMailFolderName +' exists' )
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Move Mail Folder doesnot exist on IMAP Server. Please check the value'
	drop table #TempOutput
	return

End

-----------------------------------------
-- RejectionMoveFolderName Check
-----------------------------------------


if not exists ( select 1 from #TempOutput where rtrim(ltrim(DataCol)) = 'Folder '+ @RejectionMoveFolderName +' exists' )
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Relection Mail Folder doesnot exist on IMAP Server. Please check the value'
	drop table #TempOutput
	return

End

-----------------------------------------
-- TobeProcessedFolderName Check
-----------------------------------------


if not exists ( select 1 from #TempOutput where rtrim(ltrim(DataCol)) = 'Folder '+ @TobeProcessedFolderName +' exists' )
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Tobe Processed Mail Folder doesnot exist on IMAP Server. Please check the value'
	drop table #TempOutput
	return

End

-----------------------------------------
-- ProcessedFolderName Check
-----------------------------------------


if not exists ( select 1 from #TempOutput where rtrim(ltrim(DataCol)) = 'Folder '+ @ProcessedFolderName +' exists' )
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Processed Mail Folder doesnot exist on IMAP Server. Please check the value'
	drop table #TempOutput
	return

End

-----------------------------------------
-- SentFolderName Check
-----------------------------------------


if not exists ( select 1 from #TempOutput where rtrim(ltrim(DataCol)) = 'Folder '+ @SentFolderName +' exists' )
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Sent Mail Folder doesnot exist on IMAP Server. Please check the value'
	drop table #TempOutput
	return

End


drop table #TempOutput


------------------------------------------------------------
-- Get the currently existing Account Name from the incoming 
-- mail settings.
------------------------------------------------------------

Declare @CurrentAccountName varchar(300)

select @CurrentAccountName = AccountName
from tblIncomingMailSettings

-------------------------------------------------
-- Perform the update post all the validations
-------------------------------------------------

Begin Try

	update tblIncomingMailSettings
	set LicenseKey = @LicenseKey,
	    ServerName = @ServerName,
	    AccountName = @AccountName,
	    Password = @Password,
	    FolderName = @ReceiveMailFolderName,
	    MoveFolderName = @SuccessMailFolderName,
	    SpamFolderName = @SpamFolderName,
	    RejectionMoveFolderName = @RejectionMoveFolderName,
	    TobeProcessedFolderName = @TobeProcessedFolderName,
	    ProcessedFolderName = @ProcessedFolderName,
        MailStartDate = @MailStartDate,
  	    SentFolderName = @SentFolderName,
		MailLastUID = 
					Case
							When @CurrentAccountName <> @AccountName then 0
							Else MailLastUID
					End


End Try


Begin Catch

	set @ResultFlag = 1
	set @ErrorDescription = ERROR_MESSAGE()
	return

End Catch
GO
