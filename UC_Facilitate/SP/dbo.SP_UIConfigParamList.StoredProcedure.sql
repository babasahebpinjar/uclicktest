USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIConfigParamList]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIConfigParamList]
(
	@AccessScopeID int,
	@ConfigName varchar(200)
)
As

Select tbl1.Configname , tbl2.ConfigDatatype , tbl3.AccessScopeName as Module , tbl3.AccessScopeID ,
       tbl1.ConfigValue
from tb_Config tbl1
inner join Tb_ConfigDataType tbl2 on tbl1.ConfigDataTypeID = tbl2.ConfigDataTypeID
inner join tb_AccessScope tbl3 on tbl1.AccessScopeID = tbl3.AccessScopeID
where tbl1.AccessScopeID = @AccessScopeID
and tbl1.Configname = @ConfigName

Return 0
GO
