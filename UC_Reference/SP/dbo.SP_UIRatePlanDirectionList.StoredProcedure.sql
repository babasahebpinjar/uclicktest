USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRatePlanDirectionList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UIRatePlanDirectionList]
As

Select directionId as ID , Direction as Name
from tb_Direction
where flag & 1 <> 1
and DirectionID in (1,2)
order by direction
GO
