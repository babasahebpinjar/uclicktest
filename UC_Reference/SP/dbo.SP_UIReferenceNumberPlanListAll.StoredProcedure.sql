USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIReferenceNumberPlanListAll]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIReferenceNumberPlanListAll]
As

select ID , Name
from
(
	Select 0 as ID , 'All' as Name
	union
	Select NumberplanID as ID , NumberPlan as Name
	from tb_NumberPlan
	where NumberPlanTypeID = 1
	and flag & 1 <> 1
) as tbl1
order by Name
GO
