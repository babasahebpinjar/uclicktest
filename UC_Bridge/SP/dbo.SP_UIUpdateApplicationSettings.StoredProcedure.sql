USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIUpdateApplicationSettings]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIUpdateApplicationSettings]
(
	@UserID					int,
	@AdminEmailID			varchar(100),
	@ErrorEmailID			varchar(100),
	@ReceiveMailServiceInterval	int,
	@ValidateMailServiceInterval	int,
	@SendMailServiceInterval	int,
	@OriginalDocumentFolderPath	varchar(500),
	@ApplicationLogFilePath		varchar(500),
	@ExceptionLogFilePath		varchar(500),
	@AddCCinAckMail			char(1),
	@AddCCinDocumentProcessMail	char(1),
	@AddBccinAckMail		char(1),
	@AddBccinDocumentProcessMail	char(1),
	@AddCCEmailsinAckMail		varchar(500),
	@AddBccEmailsinAckMail		varchar(500),
	@AddCCEmailsinDocumentProcessMail	varchar(500),
	@AddBccEmailsinDocumentProcessMail	varchar(500),
	@DeliveryMailFlag		char(1),
	@NetworkPathDomain		varchar(500) = NULL,
	@NetworkPathUserName		varchar(500) = NULL,
	@NetworkPathPassword		varchar(500) = NULL,
	@IsNetworkPath			char(1),
	@EmailNotificationInterval	int,
	@ResultFlag			int Output,
	@ErrorDescription		varchar(200) Output

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
	set @ErrorDescription = 'Non existant or inactive user cannot edit business parameters'
	return

End


---------------------------------------------------
-- Check if the session user has the essential
-- privilege to update the user information
---------------------------------------------------

Declare @ReturnFlag int

Exec SP_UICheckUserPrivilegeRole @UserID , 'Edit Application Settings' , @ReturnFlag output

if (@ReturnFlag = 0)
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Logged user does not have privilege to edit Application setting parameters'
	return


End

---------------------------------------------
-- Perform validation on all the parameters
---------------------------------------------

--------------------
-- Admin Email ID
--------------------

if ( ( @AdminEmailID is null ) or ( dbo.fn_ValidateEmailAddress(@AdminEmailID) = 1 ) )
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Configuration parameter AdminEmailID is NULL or not a valid email address'
	return


End

--------------------
-- Error Email ID
--------------------

if ( ( @ErrorEmailID is null ) or ( dbo.fn_ValidateEmailAddress(@ErrorEmailID) = 1 ) )
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Configuration parameter ErrorEmailID is NULL or not a valid email address'
	return


End


------------------------------------
-- Receive Mail Service Interval
------------------------------------

if ((@ReceiveMailServiceInterval is null) or (isnumeric(@ReceiveMailServiceInterval) = 0) or (@ReceiveMailServiceInterval < 0))
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Configuration parameter ReceiveMailServiceInterval is NULL or not a positive numerical value'
	return


End

------------------------------------
-- Validate Mail Service Interval
------------------------------------

if ((@ValidateMailServiceInterval is null) or (isnumeric(@ValidateMailServiceInterval) = 0) or (@ValidateMailServiceInterval < 0))
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Configuration parameter ValidateMailServiceInterval is NULL or not a positive numerical value'
	return


End

------------------------------------
-- Send Mail Service Interval
------------------------------------

if ((@SendMailServiceInterval is null) or (isnumeric(@SendMailServiceInterval) = 0) or (@SendMailServiceInterval < 0))
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Configuration parameter SendMailServiceInterval is NULL or not a positive numerical value'
	return


End

------------------------------------
-- Email Notification Interval
------------------------------------

if ((@EmailNotificationInterval is null) or (isnumeric(@EmailNotificationInterval) = 0) or (@EmailNotificationInterval < 0))
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Configuration parameter EmailNotificationInterval is NULL or not a positive numerical value'
	return


End


----------------------
-- Add CC in Ack Mail
----------------------

if ( (@AddCCinAckMail is null) or ( @AddCCinAckMail not in ('Y' , 'N')))
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Configuration parameter AddCCinAckMail is NULL or not a value in (Y, N)'
	return


End

-----------------------------------
-- Add CC in Document Process Mail
-----------------------------------

if ( (@AddCCinDocumentProcessMail is null) or ( @AddCCinDocumentProcessMail not in ('Y' , 'N')))
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Configuration parameter AddCCinDocumentProcessMail is NULL or not a value in (Y, N)'
	return


End

----------------------
-- Add Bcc in Ack Mail
----------------------

if ( (@AddBccinAckMail is null) or ( @AddBccinAckMail not in ('Y' , 'N')))
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Configuration parameter AddBccinAckMail is NULL or not a value in (Y, N)'
	return


End

---------------------------------------
-- Add Bcc in Document Process Mail
---------------------------------------

if ( (@AddBccinDocumentProcessMail is null) or ( @AddBccinDocumentProcessMail not in ('Y' , 'N')))
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Configuration parameter AddBccinDocumentProcessMail is NULL or not a value in (Y, N)'
	return


End

---------------------------------------
-- Delivery Mail Flag
---------------------------------------

if ( (@DeliveryMailFlag is null) or ( @DeliveryMailFlag not in ('Y' , 'N')))
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Configuration parameter DeliveryMailFlag is NULL or not a value in (Y, N)'
	return


End

-------------------
-- Is Network Path
-------------------

set @IsNetworkPath = isnull(@IsNetworkPath , 'N')

if ( ( @IsNetworkPath not in ('Y' , 'N')))
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Configuration parameter IsNetworkPath is not a value in (Y, N)'
	return


End


-----------------------
-- Network Path Domain
-----------------------

if ((@NetworkPathDomain is not null) and (len(@NetworkPathDomain) = 0) )
Begin

	set @NetworkPathDomain = NULL

End

if ( ( @IsNetworkPath = 'Y') and (@NetworkPathDomain is Null) )
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Configuration parameter NetworkPathDomain cannot be NULL while IsNetworkPath setting is Y'
	return


End

----------------------------
-- Network Path User Name
----------------------------

if ((@NetworkPathUserName is not null) and (len(@NetworkPathUserName) = 0) )
Begin

	set @NetworkPathUserName = NULL

End

if ( ( @IsNetworkPath = 'Y') and (@NetworkPathUserName is Null) )
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Configuration parameter NetworkPathUserName cannot be NULL while IsNetworkPath setting is Y'
	return


End

----------------------------
-- Network Path Password
----------------------------

if ((@NetworkPathPassword is not null) and (len(@NetworkPathPassword) = 0) )
Begin

	set @NetworkPathPassword = NULL

End

if ( ( @IsNetworkPath = 'Y') and (@NetworkPathPassword is Null) )
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Configuration parameter NetworkPathPassword cannot be NULL while IsNetworkPath setting is Y'
	return


End



---------------------------------------------------
-- Check all the settings which hold Folder Path
---------------------------------------------------

Declare @DirectoryPath varchar(500)

Create table #tempCommandoutput (  CommandOutput varchar(500) )

----------------------------------
-- Original Document Folder Path
----------------------------------

if ( @OriginalDocumentFolderPath is NULL )
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Configuration parameter OriginalDocumentFolderPath cannot be NULL'
	return


End

set @DirectoryPath = LTRIM(RTRIM(@OriginalDocumentFolderPath)) -- remove leading and trailing blanks

-----------------------------------------------------
-- Add '\' at the end of the directory name, incase
-- the same is missing
-----------------------------------------------------  

if ( RIGHT(@DirectoryPath , 1) <> '\')
	set @DirectoryPath = @DirectoryPath + '\'
	

-------------------------------------------------
-- Check source directory is valid or not
------------------------------------------------- 

set @cmd = 'dir ' + '"' + @DirectoryPath +'"' + '/b'

insert into #tempCommandoutput
Exec master..xp_cmdshell @cmd
	

if exists ( 
		select 1 from #tempCommandoutput where CommandOutput in
			(
			  'The system cannot find the file specified.',
			  'The system cannot find the path specified.',
			  'The network path was not found.',
			  'Access is denied.',
			  'File Not Found'
			)
	  )
Begin 

	set @ResultFlag = 1
	set @ErrorDescription = 'Folder path specified in OriginalDocumentFolderPath setting does not exist'
	return

End

delete from #tempCommandoutput


----------------------------------
-- Application Log File Path
----------------------------------

if ( @ApplicationLogFilePath is NULL )
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Configuration parameter ApplicationLogFilePath cannot be NULL'
	return


End

set @DirectoryPath = LTRIM(RTRIM(@ApplicationLogFilePath)) -- remove leading and trailing blanks

-----------------------------------------------------
-- Add '\' at the end of the directory name, incase
-- the same is missing
-----------------------------------------------------  

if ( RIGHT(@DirectoryPath , 1) <> '\')
	set @DirectoryPath = @DirectoryPath + '\'
	

-------------------------------------------------
-- Check source directory is valid or not
------------------------------------------------- 

set @cmd = 'dir ' + '"' + @DirectoryPath +'"' + '/b'

insert into #tempCommandoutput
Exec master..xp_cmdshell @cmd
	

if exists ( 
		select 1 from #tempCommandoutput where CommandOutput in
			(
			  'The system cannot find the file specified.',
			  'The system cannot find the path specified.',
			  'The network path was not found.',
			  'Access is denied.',
			  'File Not Found'
			)
	  )
Begin 

	set @ResultFlag = 1
	set @ErrorDescription = 'Folder path specified in ApplicationLogFilePath setting does not exist'
	return

End

delete from #tempCommandoutput


----------------------------------
-- Exception Log File Path
----------------------------------

if ( @ExceptionLogFilePath is NULL )
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Configuration parameter ExceptionLogFilePath cannot be NULL'
	return


End

set @DirectoryPath = LTRIM(RTRIM(@ExceptionLogFilePath)) -- remove leading and trailing blanks

-----------------------------------------------------
-- Add '\' at the end of the directory name, incase
-- the same is missing
-----------------------------------------------------  

if ( RIGHT(@DirectoryPath , 1) <> '\')
	set @DirectoryPath = @DirectoryPath + '\'
	

-------------------------------------------------
-- Check source directory is valid or not
------------------------------------------------- 

set @cmd = 'dir ' + '"' + @DirectoryPath +'"' + '/b'

insert into #tempCommandoutput
Exec master..xp_cmdshell @cmd
	

if exists ( 
		select 1 from #tempCommandoutput where CommandOutput in
			(
			  'The system cannot find the file specified.',
			  'The system cannot find the path specified.',
			  'The network path was not found.',
			  'Access is denied.',
			  'File Not Found'
			)
	  )
Begin 

	set @ResultFlag = 1
	set @ErrorDescription = 'Folder path specified in ExceptionLogFilePath setting does not exist'
	return

End

drop table #tempCommandoutput


-----------------------------------------------------------------------
-- Check all the settings which have multiple Email Address defined
-----------------------------------------------------------------------

Declare @TempStr varchar(500),
	@TempEmailAddr varchar(50)

----------------------------
-- Add CC Emails in Ack Mail
----------------------------


set @TempStr = LTRIM(RTRIM(@AddCCEmailsinAckMail)) -- remove leading and trailing blanks

while ( charindex(',' , @TempStr) > 0  )
Begin

		set @TempEmailAddr = substring(@TempStr , 1 , charindex(',' , @TempStr) - 1)
  
		if (dbo.fn_ValidateEmailAddress(@TempEmailAddr) = 1)
		Begin

			set @ResultFlag = 1
			set @ErrorDescription = 'Specified value for email address(es) in setting  AddCCEmailsinAckMail are not in correct format'
			return

		End

		set @TempStr = substring(@TempStr ,charindex(',' , @TempStr) + 1 , len(@TempStr))

End

if (dbo.fn_ValidateEmailAddress(@TempStr) = 1)
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Specified value for email address(es) in setting  AddCCEmailsinAckMail are not in correct format'
	return

End



-------------------------------
-- Add Bcc Emails in Ack Mail
-------------------------------


set @TempStr = LTRIM(RTRIM(@AddBccEmailsinAckMail)) -- remove leading and trailing blanks

while ( charindex(',' , @TempStr) > 0  )
Begin

		set @TempEmailAddr = substring(@TempStr , 1 , charindex(',' , @TempStr) - 1)
  
		if (dbo.fn_ValidateEmailAddress(@TempEmailAddr) = 1)
		Begin

			set @ResultFlag = 1
			set @ErrorDescription = 'Specified value for email address(es) in setting  AddBccEmailsinAckMail are not in correct format'
			return

		End

		set @TempStr = substring(@TempStr ,charindex(',' , @TempStr) + 1 , len(@TempStr))

End

if (dbo.fn_ValidateEmailAddress(@TempStr) = 1)
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Specified value for email address(es) in setting  AddBccEmailsinAckMail are not in correct format'
	return

End



------------------------------------------
-- Add CC Emails in Document Process Mail
------------------------------------------


set @TempStr = LTRIM(RTRIM(@AddCCEmailsinDocumentProcessMail)) -- remove leading and trailing blanks

while ( charindex(',' , @TempStr) > 0  )
Begin

		set @TempEmailAddr = substring(@TempStr , 1 , charindex(',' , @TempStr) - 1)
  
		if (dbo.fn_ValidateEmailAddress(@TempEmailAddr) = 1)
		Begin

			set @ResultFlag = 1
			set @ErrorDescription = 'Specified value for email address(es) in setting  AddCCEmailsinDocumentProcessMail are not in correct format'
			return

		End

		set @TempStr = substring(@TempStr ,charindex(',' , @TempStr) + 1 , len(@TempStr))

End

if (dbo.fn_ValidateEmailAddress(@TempStr) = 1)
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Specified value for email address(es) in setting  AddCCEmailsinDocumentProcessMail are not in correct format'
	return

End



------------------------------------------
-- Add Bcc Emails in Document Process Mail
------------------------------------------


set @TempStr = LTRIM(RTRIM(@AddBccEmailsinDocumentProcessMail)) -- remove leading and trailing blanks

while ( charindex(',' , @TempStr) > 0  )
Begin

		set @TempEmailAddr = substring(@TempStr , 1 , charindex(',' , @TempStr) - 1)
  
		if (dbo.fn_ValidateEmailAddress(@TempEmailAddr) = 1)
		Begin

			set @ResultFlag = 1
			set @ErrorDescription = 'Specified value for email address(es) in setting  AddBccEmailsinDocumentProcessMail are not in correct format'
			return

		End

		set @TempStr = substring(@TempStr ,charindex(',' , @TempStr) + 1 , len(@TempStr))

End

if (dbo.fn_ValidateEmailAddress(@TempStr) = 1)
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Specified value for email address(es) in setting  AddBccEmailsinDocumentProcessMail are not in correct format'
	return

End


-------------------------------------------------
-- Perform the update post all the validations
-------------------------------------------------

Begin Try


	update tblAppSettings
	set Value = 
	       Case
			When keyname = 'AdminEmailID' then convert(varchar(500) , @AdminEmailID)
			When keyname = 'ErrorEmailID' then convert(varchar(500) , @ErrorEmailID)
			When keyname = 'ReceiveMailServiceInterval' then convert(varchar(500) , @ReceiveMailServiceInterval)
			When keyname = 'ValidateMailServiceInterval' then convert(varchar(500) , @ValidateMailServiceInterval)
			When keyname = 'SendMailServiceInterval' then convert(varchar(500) , @SendMailServiceInterval)
			When keyname = 'OrigianlDocumentFolderPath' then convert(varchar(500) , @OriginalDocumentFolderPath)
			When keyname = 'ApplicationLogFilePath' then convert(varchar(500) , @ApplicationLogFilePath)
			When keyname = 'ExceptionLogFilePath' then convert(varchar(500) , @ExceptionLogFilePath)
			When keyname = 'AddCCinAckMail' then convert(varchar(500) , @AddCCinAckMail)
			When keyname = 'AddCCinDocumentProcessMail' then convert(varchar(500) , @AddCCinDocumentProcessMail)
			When keyname = 'AddBccinAckMail' then convert(varchar(500) , @AddBccinAckMail)
			When keyname = 'AddBccinDocumentProcessMail' then convert(varchar(500) , @AddBccinDocumentProcessMail)
			When keyname = 'AddCCEmailsinAckMail' then convert(varchar(500) , @AddCCEmailsinAckMail)
			When keyname = 'AddBccEmailsinAckMail' then convert(varchar(500) , @AddBccEmailsinAckMail)
			When keyname = 'AddCCEmailsinDocumentProcessMail' then convert(varchar(500) , @AddCCEmailsinDocumentProcessMail)
			When keyname = 'AddBccEmailsinDocumentProcessMail' then convert(varchar(500) , @AddBccEmailsinDocumentProcessMail)
			When keyname = 'DeliveryMailFlag' then convert(varchar(500) , @DeliveryMailFlag)
			When keyname = 'NetworkPathDomain' then convert(varchar(500) , @NetworkPathDomain)
			When keyname = 'NetworkPathUserName' then convert(varchar(500) , @NetworkPathUserName)
			When keyname = 'NetworkPathPassword' then convert(varchar(500) , @NetworkPathPassword)
			When keyname = 'IsNetworkPath' then  convert(varchar(500) , @IsNetworkPath)
			When keyname = 'EmailNotificationInterval' then convert(varchar(500) , @EmailNotificationInterval)
			Else Value
	       End


End Try


Begin Catch

	set @ResultFlag = 1
	set @ErrorDescription = ERROR_MESSAGE()
	return

End Catch
GO
