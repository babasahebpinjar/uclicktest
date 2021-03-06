USE [UC_Admin]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIValidateUserCredentialsMain]    Script Date: 5/2/2020 5:59:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIValidateUserCredentialsMain]
(
	@EmailID varchar(100),
	@Password varchar(15),
	@UserID int = Null Output ,
	@NameOfUser varchar(100) = Null Output ,
	@UserPrivilegeID int = NULL Output,
	@UserLoginStatusFlag int Output,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

-- Permissible Values for the @UserLoginStatusFlag are :
-- 0   User exists but login was either successful or failed
-- 1   User exists in the application but is inactive
-- 2   User EMAIL ID does not exist in the application
-- 3   Number of login attempts more than configured value so account is inactivated in application
-- 4   User will be inactivated in the application and message send that password expired
-- 5   The user login in application is successful but the password in application is about to expire in less than 5 days
-- 6   The user was found in the Active Directory, but the credentials of the user failed validation against Active Directory

Declare @LDAPConnection varchar(500),
        @EnableLDAPAuthentication int

set @ErrorDescription = NULL
set @ResultFlag = 0
set @UserLoginStatusFlag = 0 -- Default to Successful

--------------------------------------------------------
-- Check to see if the LDAP Authentication is enabled
-- or only application level authorization is required
--------------------------------------------------------

Select @EnableLDAPAuthentication = ConfigValue
from UC_Admin.dbo.tb_Config
where ConfigName = 'EnableLDAPAuthentication'
and AccessScopeID = -2 -- Administration

if ( (@EnableLDAPAuthentication is NULL) or (@EnableLDAPAuthentication <> 1 ) )
	set @EnableLDAPAuthentication = 0


if ( @EnableLDAPAuthentication = 0 )
	GOTO CHECKAPPCREDENTIALS
-----------------------------------------------
-- Get the LDAP connection string from the config
-----------------------------------------------

Select @LDAPConnection = ConfigValue
from UC_Admin.dbo.tb_Config
where ConfigName = 'LDAPConnectionString'
and AccessScopeID = -2 -- Administration

if (@LDAPConnection is NULL)
Begin

		set @ErrorDescription = 'ERROR !!!! LDAP Connection String not configured'
		set @ResultFlag = 1
		GOTO ENDPROCESS


End

Declare @SQLStr nvarchar(max)

Begin Try

	if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempADUserDetail') )
		Drop table #TempADUserDetail

    Create table #TempADUserDetail
	(
		AccountName varchar(200),
		EmailAddress varchar(100),
		GivenName varchar(200)
	)

	set @SQLStr = 
	  'SELECT  * FROM OpenQuery ' + char(10) +
	  '( ' + char(10) +
	  'ADSI, ' + char(10) + 
	  '''SELECT sAMAccountName, mail, givenname ' + char(10) +
	  'FROM  ''''' + @LDAPConnection + '''''' + char(10) +
	  'WHERE objectClass =  ''''User'''' ' + char(10) +
	  ' and objectCategory=''''person'''' ' + char(10) +
	  ' and mail = ''''' + @EmailID + '''''' + char(10) + 
	  ''') AS tblADSI'

	  --print @SQLStr

	  insert into #TempADUserDetail
	  Exec (@SQLStr)

	  if (( Select count(*) from #TempADUserDetail ) = 0 )
	  Begin

			GOTO CHECKAPPCREDENTIALS

	  End

End Try

------------------------------------------------------
-- This exception clause is an indication that the 
-- Active Directory access has some exception so we
-- need to exit the process
------------------------------------------------------
Begin Catch

		set @ErrorDescription = 'ERROR !!!! While fetching user details from Active Directory. Exception during Active Directory Access. ' + ERROR_MESSAGE()
		set @ResultFlag = 1
		GOTO ENDPROCESS

End Catch

--select * from #TempADUserDetail

----------------------------------------------------------------------------
-- Get the details of the LDAP script used for testing the user credentials
-----------------------------------------------------------------------------

Declare @LDAPCrendtialCheckScript varchar(500),
        @LDAPUserDomain varchar(100),
        @FileExists int,
		@UserName varchar(100),
		@LoginSuccessful int = 0,
		@cmd varchar(2000)

Select @LDAPCrendtialCheckScript = ConfigValue
from UC_Admin.dbo.tb_Config
where ConfigName = 'LDAPCrendtialCheckScript'
and AccessScopeID = -2 -- Administration

if (@LDAPCrendtialCheckScript is NULL)
Begin

		set @ErrorDescription = 'ERROR !!!! LDAP Credential Check Script not configured'
		set @ResultFlag = 1
		GOTO ENDPROCESS


End

---------------------------------------------------------
-- Check to ensure that the script exists in the system
----------------------------------------------------------
set @FileExists = 0

Exec master..xp_fileexist @LDAPCrendtialCheckScript , @FileExists output  

if ( @FileExists <> 1 )
Begin

	set @ErrorDescription = 'ERROR !!!! The configured LDAP Credential Script does not exist or path is invalid'
	set @ErrorDescription  = 1
	GOTO ENDPROCESS

End 

--------------------------------------------------
-- Get the config value for LDAP User Domain
--------------------------------------------------

Select @LDAPUserDomain = ConfigValue
from UC_Admin.dbo.tb_Config
where ConfigName = 'LDAPUserDomain'
and AccessScopeID = -2 -- Administration

if (@LDAPUserDomain is NULL)
Begin

		set @ErrorDescription = 'ERROR !!!! LDAP User Domain not configured'
		set @ResultFlag = 1
		GOTO ENDPROCESS


End

------------------------------------------------------------
-- Open cursor to loop through all the available account
-- name from the Active Directory till we get a successful
-- login
-------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCommandOutput') )
	Drop table #TempCommandOutput

Create Table #TempCommandOutput ( RecordData varchar(1000) )

DECLARE db_Check_User_AD_Credentials CURSOR FOR
Select Distinct GivenName
from #TempADUserDetail

OPEN db_Check_User_AD_Credentials   
FETCH NEXT FROM db_Check_User_AD_Credentials
INTO @UserName

WHILE @@FETCH_STATUS = 0   
BEGIN 

		BEGIN Try

				set @LoginSuccessful = 0

				Delete from #TempCommandOutput

				set @cmd =  @LDAPCrendtialCheckScript + ' ' + 
								'"' + @LDAPUserDomain + '"' + ' '  + 
								'"' +  @UserName + '"' + ' ' + 
								'"' +  @Password + '"' + ' ' + 
								'"' +  @LDAPConnection + '"' + ' 0 '
					 					 					 					 					 

				--print @cmd	

				insert into #TempCommandOutput
				Exec master..xp_cmdshell @cmd

				Delete from #TempCommandOutput where RecordData is NULL

				--select * from #TempCommandOutput

				if exists ( Select 1 from #TempCommandOutput where RecordData = 'Login successful' )
				Begin

						set @LoginSuccessful = 1

						CLOSE db_Check_User_AD_Credentials  
						DEALLOCATE db_Check_User_AD_Credentials 
				
						GOTO CHECKLOGINSTATUS


				End

		End Try

		BEGIN Catch
	     
				set @ErrorDescription = 'Error !!! Checking Credentials for user against Active Directory : ' + @UserName + '.' +ERROR_MESSAGE()
	     
				set @ResultFlag = 1
	            
				CLOSE db_Check_User_AD_Credentials  
				DEALLOCATE db_Check_User_AD_Credentials 
				
				GOTO ENDPROCESS
	     
		End Catch

		FETCH NEXT FROM db_Check_User_AD_Credentials
		INTO @UserName

END

CLOSE db_Check_User_AD_Credentials  
DEALLOCATE db_Check_User_AD_Credentials

CHECKLOGINSTATUS:

if ( @LoginSuccessful = 0 )
Begin

	set @UserLoginStatusFlag = 6
	GOTO ENDPROCESS

End

-------------------------------------------------------------
-- If the LDAP based authentication is enabled and
-- user credentials are verified against the Active Directory
-- then we need to just check if the user exists in the application
-- and is in active state
----------------------------------------------------------------

if exists ( select 1 from tb_Users where EmailID = @EmailID )
Begin

	if exists ( select 1 from tb_Users where EmailID = @EmailID and UserStatusID = 1 )
	Begin
		
			Select @UserID = UserID,
				   @NameOfUser = Name,
				   @UserPrivilegeID = userprivilegeID
			from tb_users
			where EmailID = @EmailID	 
			and UserStatusID = 1 

			GOTO ENDPROCESS

    End

	Else
	Begin

			set @UserLoginStatusFlag = 1 -- User exists in the system but inactive
			GOTO ENDPROCESS

	End

End

Else
Begin

	set @UserLoginStatusFlag = 2 -- User with the email address does not exist in the system
	GOTO ENDPROCESS

End



CHECKAPPCREDENTIALS:

------------------------------------------------------
-- This portion of code will only run for those users
-- which are not part of the Active Directory or
-- LDAP Authentication is disabled and all users will
-- be authorized against the application
-------------------------------------------------------

--------------------------------------------------------------
-- Call the procedure to perform user credential verification
-- against the application
--------------------------------------------------------------

Begin Try

		Exec SP_UIValidateUserCredentials @EmailID , @Password , @UserID Output,
		                                  @NameOfUser Output , @UserPrivilegeID Output,
										  @UserLoginStatusFlag Output

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!! When Authorizing the user information against application. ' + ERROR_MESSAGE()
		set @ResultFlag = 1
		GOTO ENDPROCESS

End Catch


ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempADUserDetail') )
	Drop table #TempADUserDetail

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCommandOutput') )
	Drop table #TempCommandOutput
GO
