USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIEntityGroupTypeList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIEntityGroupTypeList]
As

Select EntityGroupTypeID as ID , EntityGroupType as Name
From tb_EntityGroupType
where flag & 1 <> 1
order by EntityGroupType
GO
