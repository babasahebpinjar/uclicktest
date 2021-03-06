USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIDestinationGroupList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIDestinationGroupList]
As

select distinct tbl1.EntityGroupID as ID , tbl1.EntityGroup as Name
from tb_EntityGroup tbl1
inner join tb_EntityGroupMember tbl2 on tbl1.EntityGroupID = tbl2.EntityGroupID
inner join tb_Destination tbl3 on tbl2.InstanceID = tbl3.DestinationID
where EntityGroupTypeID = -2
and tbl3.NumberPlanID = -1 -- Only Routing number plan grouping
and tbl1.Flag & 1 <> 1
order by tbl1.EntityGroup
GO
