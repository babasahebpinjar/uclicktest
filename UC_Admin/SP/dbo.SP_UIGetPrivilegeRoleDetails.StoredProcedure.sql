USE [UC_Admin]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetPrivilegeRoleDetails]    Script Date: 5/2/2020 5:59:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Procedure [dbo].[SP_UIGetPrivilegeRoleDetails]
(
   @PrivilgeID int,
   @AccessScopeID int, -- 0 means All
   @UserID int
)
--With Encryption 
As


select tbl1.AccessRolesID , tbl1.AccessRolesName ,tbl2.AccessScopeID , tbl2.AccessScopeName
from tb_AccessRoles tbl1
inner join tb_AccessScope tbl2 on tbl1.AccessScopeID = tbl2.AccessScopeID
inner join Tb_PrivilegeAccessRoles tbl3 on tbl1.AccessRolesID = tbl3.AccessRolesID
where tbl3.UserPrivilegeID = @PrivilgeID
and tbl2.AccessScopeID = 
		Case 
				When @AccessScopeID = 0 then tbl2.AccessScopeID
				Else @AccessScopeID
		End
order by tbl2.AccessScopeName , tbl1.AccessRolesName

Return



GO
