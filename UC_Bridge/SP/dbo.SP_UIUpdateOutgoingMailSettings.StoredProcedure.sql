USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIUpdateOutgoingMailSettings]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIUpdateOutgoingMailSettings] 
(
	@UserID				int,
	@ServerName			varchar(100),
	@AccountName		varchar(300),
	@Port               int,
	@Password			varchar(100),
	@SSL                char(1),
	@ProxyServer        varchar(100) = NULL,
	@ProxyPort          int = NULL,
	@ResultFlag			int Output,
	@ErrorDescription   Varchar(200) Output
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
	set @ErrorDescription = 'Non existant or inactive user cannot edit Outgoing Email setting parameters'
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
	set @ErrorDescription = 'Logged user does not have privilege to edit Outgoing Email setting parameters'
	return


End

--------------------------------------
-- Check configuration parameters are
-- not NULL
--------------------------------------

--------------
-- ServerName
--------------


if ( @ServerName is NULL )
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Configuration parameter ServerName cannot be NULL'
	return


End

--------------
-- AccountName
--------------

if (( @AccountName is NULL ) or (dbo.fn_ValidateEmailAddress(@AccountName) = 1) )
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Configuration parameter AccountName cannot be NULL or an invalid email address'
	return


End

--------------
-- Password
--------------

if ( @Password is NULL )
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Configuration parameter Password cannot be NULL'
	return


End


--------------
-- SSL
--------------

if ( (@SSL is null) or ( @SSL not in ('Y' , 'N')))
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Configuration parameter SSL is NULL or not a value in (Y, N)'
	return


End

--------------
-- Port
--------------

if ((@Port is null) or (isnumeric(@Port) = 0) or (@Port <= 0))
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Configuration parameter Port is NULL or not a positive numerical value'
	return


End

----------------------------------------------------------
-- Add Code to check for the Proxy Server details, if
-- provided
----------------------------------------------------------

if ((@ProxyServer is not null) and (LEN(@ProxyServer) = 0))
Begin

	  set @ProxyServer = NULL
	  set @ProxyPort = NULL

End

if ( @ProxyServer is not NULL )
Begin

    -------------------------------------------------
	-- Check to ensure that proxy port is provided
	--------------------------------------------------

	if ((@ProxyPort is null) or (isnumeric(@ProxyPort) = 0) or (@ProxyPort <= 0))
	Begin

		set @ResultFlag = 1
		set @ErrorDescription = 'Configuration parameter Proxy Port is NULL or not a positive numerical value'
		return


	End

End

-----------------------------------------------------
-- Get the License value from the incoming settings
-- for running the connection check script
-----------------------------------------------------

Declare @LicenseKey	varchar(100)

Select @LicenseKey = LicenseKey
from tblIncomingMailSettings
where ClientID = 1 -- Default Redundant where clause

if ( @LicenseKey is NULL )
Begin

		set @ResultFlag = 1
		set @ErrorDescription = 'License Key is still not defined for IMAP and SMTP connectivity via Client'
		return

End

---------------------------------------------------------------------
-- Check Connectivity using the new credentials to ensure SMTP works
---------------------------------------------------------------------

Create table #TempOutput (DataCol varchar(500) )

insert into #TempOutput
Exec SP_CheckSMTPConnectivity @ServerName , @AccountName , @Password , @Port , @SSL ,
                              @ProxyServer , @ProxyPort , @LicenseKey

delete from #TempOutput where DataCol is NULL

delete from #TempOutput where CHARINDEX('failed' ,DataCol) = 0 

if exists ( select 1 from #TempOutput )
Begin

    set @ResultFlag = 1

	select @ErrorDescription = datacol
	from #TempOutput
	
	drop table #TempOutput

	return



End

drop table #TempOutput


-------------------------------------------------
-- Perform the update post all the validations
-------------------------------------------------

Begin Try

	update tblOutgoingMailSettings
	set ServerName	= @ServerName ,
	    AccountName	= @AccountName,
	    FromAddress = @AccountName,
	    PortNumber  = @Port , 
	    Password = @Password,
	    SSL  = Case
					When @SSL = 'Y' Then 1
					When @SSL = 'N' then 0
	           End,
       ProxyServerName = 
					Case
							When @ProxyServer is not NUll then @ProxyServer
							Else ProxyServerName
					End,
       ProxyServerPort = 
					Case
							When @ProxyServer is not NUll then @ProxyPort
							Else NULL
					End


End Try


Begin Catch

	set @ResultFlag = 1
	set @ErrorDescription = ERROR_MESSAGE()
	return

End Catch

GO
