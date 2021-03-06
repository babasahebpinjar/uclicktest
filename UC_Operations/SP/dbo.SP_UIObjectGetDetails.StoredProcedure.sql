USE [UC_Operations]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIObjectGetDetails]    Script Date: 5/2/2020 6:25:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIObjectGetDetails]
(
	@ObjectID int
)
As

select obj.ObjectID , obj.ObjectName , objtype.ObjectTypeName as ObjectType,
       obj.ModifiedDate, usr.Name as ModifiedBy
from tb_Object obj
inner join tb_ObjectType objtype on obj.ObjectTypeID = objtype.ObjectTypeID
inner join UC_Admin.dbo.tb_Users usr on obj.ModifiedByID = usr.userid
where obj.ObjectID = @ObjectID
and obj.flag & 1 <> 1
and objtype.flag & 1 <> 1

return 0
GO
