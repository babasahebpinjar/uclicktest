USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UINumberPlanTypeList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UINumberPlanTypeList]
As

Select NumberPlanTypeID as ID , NumberPlanType as Name
from tb_NumberPlanType
where flag & 1 <> 1
order by NumberPlanType
GO
