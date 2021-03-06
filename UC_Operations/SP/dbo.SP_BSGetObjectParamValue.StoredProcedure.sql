USE [UC_Operations]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSGetObjectParamValue]    Script Date: 5/2/2020 6:25:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSGetObjectParamValue]
(
	@InstanceID int,
	@ParamName varchar(200),
	@ReturnValue varchar(1000) Output
)
As

---------------------------------------------------------
-- Get the value of the parameter based on the object
-- of the instance
---------------------------------------------------------

select @ReturnValue = tbl3.ObjectParamValue
from tb_ObjectInstance tbl1
inner join tb_Object tbl2 on tbl1.ObjectID = tbl2.ObjectID
inner join tb_ObjectParam tbl3 on tbl2.ObjectID = tbl3.ObjectID
inner join tb_ObjectTypeParam tbl4 on tbl3.ObjectTypeParamID = tbl4.ObjectTypeParamID
inner join tb_Parameter tbl5 on tbl4.ParameterID = tbl5.ParameterID
where tbl1.ObjectInstanceID = @InstanceID
and tbl5.ParameterName = @ParamName

Return 0
GO
