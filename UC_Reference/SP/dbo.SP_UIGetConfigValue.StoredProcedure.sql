USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetConfigValue]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create procedure [dbo].[SP_UIGetConfigValue]
(
	@ConfigName varchar(200),
	@AccessScopeID int,
	@ConfigValue varchar(1000) Output
)
As

-----------------------------------------------------
-- Get the Config value for the passed parameter
-----------------------------------------------------

select @ConfigValue = ConfigValue
from UC_Admin.dbo.tb_Config
where ConfigName = @ConfigName
and AccessScopeID = @AccessScopeID

Return 0
GO
