USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetAllCustomFeature]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UIGetAllCustomFeature]
As

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCustomConfigValues') )
		Drop table #TempCustomConfigValues

create table #TempCustomConfigValues
(
	Configname varchar(1000),
	AccessScopeID int
)

----------------------------------------------
-- Add the Custom Config Feature names to the 
-- list
----------------------------------------------

insert into #TempCustomConfigValues values ('EnableCustomServiceLevelAssignment' , -4)
insert into #TempCustomConfigValues values ('EnableMasterLogExtract' , -4)

---------------------------------------------------------------
-- Select the name and values from the tb_config table
---------------------------------------------------------------

select tbl1.ConfigName as Name , isnull(tbl2.ConfigValue,0) as Value
from #TempCustomConfigValues tbl1
left join ReferenceServer.UC_Admin.dbo.tb_config tbl2 on tbl1.Configname = tbl2.ConfigName
                                                    and
													     tbl1.AccessScopeID = tbl2.AccessScopeID


if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCustomConfigValues') )
		Drop table #TempCustomConfigValues

Return 0
GO
