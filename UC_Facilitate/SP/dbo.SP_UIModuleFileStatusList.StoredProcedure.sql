USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIModuleFileStatusList]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[SP_UIModuleFileStatusList]
(
	@AccessScopeID  int
)
 AS

select FileStatus as Name
from tb_AccessScopeFilestatus
where AccessScopeID = @AccessScopeID
order by FileStatus

Return 0

















GO
