USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetBusinessParameters]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetBusinessParameters]
(
	@UserID int,
	@ParameterName varchar(200)

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

	select NULL as ParameterName , NULL as ParameterValue
	return

End


---------------------------------------------------
--  Check if the session user has the essential
-- privilege to update the user information
---------------------------------------------------

Declare @ReturnFlag int

Exec SP_UICheckUserPrivilegeRole @UserID , 'Access Business Parameters' , @ReturnFlag output

if (@ReturnFlag = 0)
Begin

	select NULL as ParameterName , NULL as ParameterValue
	return

End


-------------------------------------------
-- In case everything is okay, return the 
-- dataset to be displayd on UI
-------------------------------------------

Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000)

----------------------------------------
-- Construct the initial part of the
-- Dynamic Search SQL
----------------------------------------

set @SQLStr = 'Select configname , configvalue '+
              ' From tb_config '

--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------

set @Clause1 = 
               Case
		   When (@ParameterName is NULL) then ''
		   When ( ( Len(@ParameterName) =  1 ) and ( @ParameterName = '%') ) then ''
		   When ( right(@ParameterName ,1) = '%' ) then ' where ConfigName like ' + '''' + substring(@ParameterName,1 , len(@ParameterName) - 1) + '%' + ''''
		   Else ' where ConfigName like ' + '''' + @ParameterName + '%' + ''''
	       End


-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1

Exec (@SQLStr)

Return
GO
