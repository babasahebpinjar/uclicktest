USE [UC_Admin]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetUSerDetailsByPrivilegeID]    Script Date: 02-05-2020 14:39:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UIGetUSerDetailsByPrivilegeID]
(
	@UserPrivilegeID int
)
As

Select UserID as ID , Name 
from tb_users
where UserPrivilegeID = @UserPrivilegeID
GO
