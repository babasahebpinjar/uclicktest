USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetUserDetails]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetUserDetails]
(
    @UserName varchar(30) = NULL,
    @EmailID varchar(100) = NULL,
    @UserStatusID int,
    @PrivilegeID int
)
--With Encryption
As


Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000),
	@Clause2 varchar(1000)

----------------------------------------
-- Construct the initial part of the
-- Dynamic Search SQL
----------------------------------------

set @SQLStr = 'Select tbl1.Name , tbl1.EmailID , tbl2.UserPrivilege , tbl3.UserStatus , tbl1.UserID '+
              ' From tb_Users tbl1 ' +
	      ' inner join tb_UserPrivilege tbl2 on tbl1.UserPrivilegeID = tbl2.UserPrivilegeID ' +
	      ' inner join tb_UserStatus tbl3 on tbl1.UserStatusID = tbl3.UserStatusID '

if ( @UserStatusID <> 0 )
Begin
	      set @SQLStr =  @SQLStr + ' where tbl1.UserStatusID = ' + convert(varchar(20) , @UserStatusID)

End

Else
Begin

	      set @SQLStr =  @SQLStr + ' where tbl1.UserStatusID = tbl1.UserStatusID '
End


if ( @PrivilegeID <> 0 )
Begin
	      set @SQLStr =  @SQLStr + ' and tbl1.UserPrivilegeID = ' + convert(varchar(20) , @PrivilegeID)

End

Else
Begin

	      set @SQLStr =  @SQLStr + ' and tbl1.UserPrivilegeID = tbl1.UserPrivilegeID '
End

--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------

set @Clause1 = 
               Case
		   When (@UserName is NULL) then ''
		   When ( ( Len(@UserName) =  1 ) and ( @UserName = '%') ) then ''
		   When ( right(@UserName ,1) = '%' ) then ' and tbl1.Name like ' + '''' + substring(@UserName,1 , len(@UserName) - 1) + '%' + ''''
		   Else ' and tbl1.Name like ' + '''' + @UserName + '%' + ''''
	       End


set @Clause2 = 
               Case
		   When (@EmailID is NULL) then ''
		   When ( ( Len(@EmailID) =  1 ) and ( @EmailID = '%') ) then ''
		   When ( right(@EmailID ,1) = '%' ) then ' and tbl1.EmailID like ' + '''' + substring(@EmailID,1 , len(@EmailID) - 1) + '%' + ''''
		   Else ' and tbl1.EmailID like ' + '''' + @EmailID + '%' + ''''
	       End

-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1 + @Clause2

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by name , emailid , UserPrivilege , UserStatus' 

print @SQLStr

Exec (@SQLStr)

Return



GO
