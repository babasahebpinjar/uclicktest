USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIAccessScopeList]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[SP_UIAccessScopeList]
 AS

select AccessScopeID as ID, AccessScopeName as Name
from tb_AccessScope
order by 1 desc

Return 0

















GO
