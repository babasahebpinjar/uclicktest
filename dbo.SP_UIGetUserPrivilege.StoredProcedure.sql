USE [UC_Admin]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetUserPrivilege]    Script Date: 02-05-2020 14:39:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_UIGetUserPrivilege]
--With Encryption 
As

select UserPrivilegeID as ID, UserPrivilege as Name
From tb_UserPrivilege
where UserPrivilegeID > 0

Return
GO
