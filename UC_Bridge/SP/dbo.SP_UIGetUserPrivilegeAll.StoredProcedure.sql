USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetUserPrivilegeAll]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetUserPrivilegeAll]
--With Encryption
As

select 0, 'All'
union
select UserPrivilegeID , UserPrivilege
From tb_UserPrivilege

Return
GO
