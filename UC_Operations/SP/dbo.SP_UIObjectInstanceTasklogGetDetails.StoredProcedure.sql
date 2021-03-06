USE [UC_Operations]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIObjectInstanceTasklogGetDetails]    Script Date: 5/2/2020 6:25:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UIObjectInstanceTasklogGetDetails]
(
	@ObjectInstanceID int
)
As

Select ObjectInstanceTaskLogID , ObjectInstanceID,
       TaskName , TaskStartDate , TaskEndDate ,
	   CommentLog , Measure1 , Measure2 , Measure3,
	   Measure4 , Measure5
from tb_ObjectInstanceTasklog
where ObjectInstanceID = @ObjectInstanceID
order by TaskStartDate
GO
