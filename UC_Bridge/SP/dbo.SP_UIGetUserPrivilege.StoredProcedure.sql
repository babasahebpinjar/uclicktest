USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetUserPrivilege]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetUserPrivilege]
--With Encryption
As

select UserPrivilegeID , UserPrivilege
From tb_UserPrivilege

Return
GO
