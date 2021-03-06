USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIUpdateBusinessParameters]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_UIUpdateBusinessParameters]
(
   @ParamName Varchar(100),
   @ParamValue Varchar(1000),
   @UserID int,
   @ResultFlag int Output,
   @ErrorDescription varchar(1000) = NULL Output
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

Exec SP_UICheckUserPrivilegeRole @UserID , 'Edit Business Parameters' , @ReturnFlag output

if (@ReturnFlag = 0)
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Logged user does not have privilege to edit business parameters'
	return


End


if (@ParamValue is NULL)
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Cannot specify NULL value for business parameter'
	return

End

----------------------------------------------------
-- Perform essential vlidation on parameter, depending
-- on its type
-----------------------------------------------------

------------------------
-- Check Folder Exists
------------------------

if ( @ParamName in (
			'VendorOfferDirectory',
			'OfferUploadSourcePath',
			'OfferUploadDestinationPath',
			'ParseConfigDirectory'
		   )
   )
Begin

        Declare @DirectoryPath varchar(100)

	set @DirectoryPath = LTRIM(RTRIM(@ParamValue)) -- remove leading and trailing blanks

	-----------------------------------------------------
	-- Add '\' at the end of the directory name, incase
	-- the same is missing
	-----------------------------------------------------  

	if ( RIGHT(@DirectoryPath , 1) <> '\')
		set @DirectoryPath = @DirectoryPath + '\'
		

	-------------------------------------------------
	-- Check source directory is valid or not
	------------------------------------------------- 

	Create table #tempCommandoutput 
	(
	  CommandOutput varchar(500)
	)

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
		set @ErrorDescription = 'Folder path specified does not exist'
		return

	End

	drop table #tempCommandoutput

 

End


------------------------
-- Check File Exists
------------------------

if ( @ParamName in (
			'ParseSingleSheetVendorOfferExcel',
			'ParseMultipleSheetVendorOfferExcel',
			'ParseSingleSheetVendorOfferXLX',
			'ParseMultipleSheetVendorOfferXLX',
			'ParseSingleSheetVendorOfferSLK',
			'ParseSingleSheetVendorOfferCSV',
			'CreateExcelVendorOffer',
			'SendAlertViaSMTP',
			'CheckIMAPConnectivity',
			'CheckSMTPConnectivity',
			'PerlExecutable'
		   )
   )
Begin

	Declare @FileExists int = 0,
	        @TempFileName varchar(100)
		
 
        set @TempFileName = LTRIM(RTRIM(@ParamValue)) -- remove leading and trailing blanks

	Exec master..xp_fileexist  @TempFileName , @FileExists output 

	if ( @FileExists <> 1 )
	Begin

		set @ResultFlag = 1
		set @ErrorDescription = 'File Name specified does not exist'
		return

	End


End


-------------------------------------
-- Check value is a positive number
-------------------------------------

if ( @ParamName in (
			'EffectiveDateFutureDays',
			'RateIncreasePeriod',
			'PercentContentDeviation',
			'DestinationNameLength',
			'MaxLoginAttempts',
			'PasswordAgingDays',
			'AllowExtendedVendorSources'
		   )
   )
Begin

        Declare @NumericFlag int = 0
        
        set @ParamValue = LTRIM(RTRIM(@ParamValue)) -- remove leading and trailing blanks
        set @NumericFlag = ISNUMERIC(@ParamValue)      
 
	if ( ( @NumericFlag = 0)or (@ParamValue < 0))
	Begin

		set @ResultFlag = 1
		set @ErrorDescription = 'Specified value is either not numeric or lesser than zero'
		return

	End


End



--------------------------------------
-- Check Email Address Semantics
--------------------------------------

if ( @ParamName in (
			'RegisterOfferAlertEmailAddress',
			'ValidateOfferAlertEmailAddress',
			'UploadOfferAlertEmailAddress'
		   )
   )
Begin

        Declare @TempStr varchar(1000),
		@TempEmailAddr varchar(50),
		@EmailValidFlag int = 0

        set @TempStr = LTRIM(RTRIM(@ParamValue)) -- remove leading and trailing blanks
 
		while ( charindex(';' , @TempStr) > 0  )
		Begin

				set @TempEmailAddr = substring(@TempStr , 1 , charindex(';' , @TempStr) - 1)
		 
				if (dbo.fn_ValidateEmailAddress(@TempEmailAddr) = 1)
				Begin

					set @ResultFlag = 1
					set @ErrorDescription = 'Specified value for email address(es) not in correct format'
					return

				End

				set @TempStr = substring(@TempStr ,charindex(';' , @TempStr) + 1 , len(@TempStr))

		End

		if (dbo.fn_ValidateEmailAddress(@TempStr) = 1)
		Begin

			set @ResultFlag = 1
			set @ErrorDescription = 'Specified value for email address(es) not in correct format'
			return

		End


End


----------------------------------------------------------------------
-- Special Check for SkipCountryCodes and AllowedVendorOfferExtensions
----------------------------------------------------------------------

if ( @ParamName in (
			'SkipCountryCodes',
			'AllowedVendorOfferExtensions'
		   )
   )
Begin

        Declare @TempString varchar(100),
		@TempValue varchar(50),
		@StringnumericFlag int = 0

		if ( (@ParamName = 'SkipCountryCodes') and (@ParamValue = '|' ) )
		Begin

		    set @ParamValue = NULL
			GOTO UPDATECONFIG

		End

        set @TempString = LTRIM(RTRIM(@ParamValue)) -- remove leading and trailing blanks
 
		while ( charindex('|' , @TempString) > 0  )
		Begin

				set @TempValue = substring(@TempString , 1 , charindex('|' , @TempString) - 1)
				
	 
				if ( (@ParamName = 'SkipCountryCodes') and (isnumeric(@TempValue) = 0))
				Begin

					set @ResultFlag = 1
					set @ErrorDescription = 'Specified value for skip country codes are not numeric'
					return

				End

				if ( (@ParamName = 'AllowedVendorOfferExtensions') and (substring(@TempValue ,1,1) <> '.'))
				Begin

					set @ResultFlag = 1
					set @ErrorDescription = 'Specified value for Allowed Vendor Offer Extensions is not is correct format'
					return

				End

				set @TempString = substring(@TempString ,charindex('|' , @TempString) + 1, len(@TempString))

		End
		

		if ( (@ParamName = 'SkipCountryCodes') and (isnumeric(@TempString) = 0))
		Begin

			set @ResultFlag = 1
			set @ErrorDescription = 'Specified value for skip country codes are not numeric'
			return

		End

		if ( (@ParamName = 'AllowedVendorOfferExtensions') and (substring(@TempString ,1,1) <> '.'))
		Begin

			set @ResultFlag = 1
			set @ErrorDescription = 'Specified value for Allowed Vendor Offer Extensions is not is correct format'
			return

		End


End


UPDATECONFIG:

--------------------------------------------------------
-- Post All validations, update the parameter value
--------------------------------------------------------

Begin Try

	update tb_config
	set configvalue = LTRIM(RTRIM(@ParamValue))
	where configname = @ParamName

End Try

Begin Catch

	set @ResultFlag = 1
	set @ErrorDescription = ERROR_MESSAGE()
	return

End Catch


return
GO
