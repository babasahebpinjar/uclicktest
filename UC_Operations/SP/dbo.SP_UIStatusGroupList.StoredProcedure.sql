USE [UC_Operations]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIStatusGroupList]    Script Date: 5/2/2020 6:25:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UIStatusGroupList]
As

select StatusGroupID as ID , StatusGroupName as Name
from tb_StatusGroup
where flag & 1 <> 1
GO
