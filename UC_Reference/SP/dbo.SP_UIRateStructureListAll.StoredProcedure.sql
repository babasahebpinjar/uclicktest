USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRateStructureListAll]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UIRateStructureListAll]
As

select ID , Name 
From
(
	select '0' as ID , 'All' as Name
	Union
	Select RateStructureID as ID , RateStructure as Name
	from tb_RateStructure
	where flag & 1 <> 1
) tbl1
order by ID
GO
