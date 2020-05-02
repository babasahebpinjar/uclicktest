USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIDirectionList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIDirectionList]
As

Select directionId as ID , Direction as Name
from tb_Direction
where flag & 1 <> 1
order by direction
GO
