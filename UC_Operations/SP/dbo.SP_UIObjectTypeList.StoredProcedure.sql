USE [UC_Operations]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIObjectTypeList]    Script Date: 5/2/2020 6:25:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UIObjectTypeList]
As

Select ObjectTypeID as ID , ObjectTypeName as Name
from tb_ObjectType
where Flag & 1 <> 1
GO
