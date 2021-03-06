USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIServiceLevelList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIServiceLevelList]
(
	@DirectionID int = NULL
)
As

Select ServiceLevelID , ServiceLevel , ServiceLevelAbbrv,
	   RoutingFlag,
	   PriorityOrder,
	   dr.DirectionID,
	   dr.Direction,
	   sl.ModifiedDate,
	   UC_Admin.dbo.FN_GetUserName(sl.ModifiedByID) as ModifiedByUser
from tb_ServiceLevel sl
inner join tb_Direction dr on sl.DirectionID = dr.DirectionID
where sl.flag & 1 <> 1
and sl.DirectionID  = 
       Case
			When isNULL(@DirectionID , 0) = 0 then sl.DirectionID
			Else @DirectionID
	   End
order by PriorityOrder
GO
