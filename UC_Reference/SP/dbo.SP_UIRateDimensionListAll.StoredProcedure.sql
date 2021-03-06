USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRateDimensionListAll]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRateDimensionListAll]
As

select ID , Name 
From
(
	select '0' as ID , 'All' as Name
	Union
	Select RateDimensionID as ID , RateDimension as Name
	from tb_RateDimension
	where flag & 1 <> 1
) tbl1
order by ID
GO
