USE [UC_Bridge]
GO
/****** Object:  View [dbo].[vw_CountryGroup]    Script Date: 5/2/2020 6:44:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE     VIEW [dbo].[vw_CountryGroup]
--With Encryption
AS

select EntityGroupID as GroupID , EntityGroup as [Group] , EntityGroupAbbrv as GroupAbbrv
from Referenceserver.Uc_Reference.dbo.tb_EntityGroup
where EntityGroupTypeID = -4  -- Country Group 
and Flag & 1 <> 1
	

GO
