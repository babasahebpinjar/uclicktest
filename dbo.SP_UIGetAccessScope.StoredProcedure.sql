USE [UC_Admin]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetAccessScope]    Script Date: 02-05-2020 14:39:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Procedure [dbo].[SP_UIGetAccessScope]
--With Encryption 
As


select accessScopeId , AccessScopeName
from
(
	select 0 as accessScopeId , 'All' as AccessScopeName
	union
	select accessScopeId , AccessScopeName
	from tb_AccessScope
) tbl1
order by abs(accessScopeId)

Return
GO
