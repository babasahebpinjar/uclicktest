USE [UC_Admin]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetUserPrivilegeAll]    Script Date: 5/2/2020 5:59:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_UIGetUserPrivilegeAll]
--With Encryption
As

select 0 as ID, 'All' as Name
union
select UserPrivilegeID as ID, UserPrivilege as Name
From tb_UserPrivilege

Return
GO
