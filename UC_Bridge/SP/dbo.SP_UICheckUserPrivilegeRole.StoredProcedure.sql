USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICheckUserPrivilegeRole]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_UICheckUserPrivilegeRole]
(
    @UserID int,
    @AccessRoles varchar(50),
    @ResultFlag int Output
)
--With Encryption
As


set @ResultFlag = 0

-----------------------------------------------------------------
-- Check if the privilege assigned to the session user provides
-- the essential roles
-----------------------------------------------------------------

if exists (
		select 1 
		from tb_Users tbl1
		inner join tb_UserPrivilege tbl2 on tbl1.UserPrivilegeID = tbl2.UserPrivilegeID
		inner join tb_PrivilegeAccessRoles tbl3 on tbl2.UserPrivilegeID = tbl3.UserPrivilegeID
		inner join tb_AccessRoles tbl4 on tbl3.AccessRolesID = tbl4.AccessRolesID
		where tbl1.UserID = @UserID
		and tbl1.UserStatusID = 1 
		and tbl4.AccessRolesName = @AccessRoles
	  )
Begin

		set @ResultFlag = 1
End


Return
GO
