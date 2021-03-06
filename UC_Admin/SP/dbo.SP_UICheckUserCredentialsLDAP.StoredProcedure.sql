USE [UC_Admin]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICheckUserCredentialsLDAP]    Script Date: 5/2/2020 5:59:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UICheckUserCredentialsLDAP]
(
	@EmailAddress varchar(100),
    @Password varchar(100),
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int output
)
As

--Declare @EmailAddress varchar(100) = 'Buyrates@xl.co.id',
--        @Password varchar(100) = 'password*1',
--		@ErrorDescription varchar(2000),
--		@ResultFlag int

Declare @LDAPConnection varchar(500)

set @ErrorDescription = NULL
set @ResultFlag = 0

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
	  ' and mail = ''''' + @EmailAddress + '''''' + char(10) + 
	  ''') AS tblADSI'

	  --print @SQLStr

	  insert into #TempADUserDetail
	  Exec (@SQLStr)

	  if (( Select count(*) from #TempADUserDetail ) = 0 )
	  Begin

	  		set @ErrorDescription = 'ERROR !!!! No Records exist in Active Directory for email address : ' + @EmailAddress
			set @ResultFlag = 1
			GOTO ENDPROCESS

	  End

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!!! While fetching user details from Active Directory. ' + ERROR_MESSAGE()
		set @ResultFlag = 1
		GOTO ENDPROCESS

End Catch

select * from #TempADUserDetail

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
Select Distinct AccountName
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
	     
				set @ErrorDescription = 'Error !!! Checking Credntials for user : ' + @UserName + '.' +ERROR_MESSAGE()
	     
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

	set @ErrorDescription = 'Error !!! Login Credentials failed validation against Active Directory for user'
	set @ResultFlag = 1

End

ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempADUserDetail') )
	Drop table #TempADUserDetail

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCommandOutput') )
	Drop table #TempCommandOutput
GO
