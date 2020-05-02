USE [UC_Operations]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICDRObjectList]    Script Date: 5/2/2020 6:25:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UICDRObjectList]
As

Select ObjectID as ID ,  ObjectName as Name
from tb_Object
where objectTypeID = 100 -- CDR File
and Flag & 1 <> 1

Return 0
GO
