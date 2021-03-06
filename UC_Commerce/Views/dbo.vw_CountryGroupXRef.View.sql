USE [UC_Commerce]
GO
/****** Object:  View [dbo].[vw_CountryGroupXRef]    Script Date: 5/2/2020 6:15:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     VIEW [dbo].[vw_CountryGroupXRef]
--With Encryption
AS

select tbl1.EntityGroupID as GroupID , EntityGroup as [Group] , EntityGroupAbbrv as GroupAbbrv,
       tbl3.CountryID , tbl3.CountryCode
from UC_Reference.dbo.tb_EntityGroup tbl1
inner join UC_Reference.dbo.tb_EntityGroupMember tbl2 on tbl1.EntityGroupID = tbl2.EntityGroupID
inner join UC_Reference.dbo.tb_Country tbl3 on tbl2.InstanceID = tbl3.CountryID
where tbl1.EntityGroupTypeID = -4  -- Country Group 
and tbl1.Flag & 1 <> 1
	


GO
