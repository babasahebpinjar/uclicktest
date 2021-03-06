USE [UC_Admin]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetPrivilegeDetails]    Script Date: 5/2/2020 5:59:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_UIGetPrivilegeDetails]
(
    @UserPrivilege varchar(50) = NULL
)
--With Encryption 
As


Declare @SQLStr varchar(5000),
        @Clause1 varchar(1000)

----------------------------------------
-- Construct the initial part of the
-- Dynamic Search SQL
----------------------------------------


set @SQLStr = 'select tbl1.UserPrivilegeID , tbl1.UserPrivilege ' +
	      ' from tb_UserPrivilege tbl1 ' +
	      ' where tbl1.UserPrivilegeID > 0'



--------------------------------------------
-- Check the input parameters to decide on
-- the conditional clause for the search
--------------------------------------------

set @Clause1 = 
               Case
		   When (@UserPrivilege is NULL) then ''
		   When ( ( Len(@UserPrivilege) =  1 ) and ( @UserPrivilege= '%') ) then ''
		   When ( right(@UserPrivilege,1) = '%' ) then ' and tbl1.Name like ' + '''' + substring(@UserPrivilege,1 , len(@UserPrivilege) - 1) + '%' + ''''
		   Else ' and tbl1.UserPrivilege like ' + '''' + @UserPrivilege+ '%' + ''''
	       End



-------------------------------------------------
-- Prepare the complete dynamic search query
-- and execute
-------------------------------------------------

set @SQLStr = @SQLStr + @Clause1 

--------------------------------------------
-- Add the sorting clause to the resut set
--------------------------------------------

set @SQLStr = @SQLStr  + ' order by  UserPrivilege ' 

print @SQLStr

Exec (@SQLStr)

Return




GO
