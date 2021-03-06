USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIEntityGroupList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIEntityGroupList]
(
	@EntityGroupTypeID int
)
As

select EntityGroupID , EntityGroup , EntityGroupAbbrv , EntityGroupTypeID,
       ModifiedDate , UC_Admin.dbo.FN_GetUserName(ModifiedByID) as ModifiedByUser
from tb_EntityGroup
where EntityGroupTypeID = @EntityGroupTypeID
and flag & 1 <> 1
order by EntityGroup
GO
