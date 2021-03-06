USE [UC_Operations]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIObjectList]    Script Date: 5/2/2020 6:25:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UIObjectList]
(
	@ObjectTypeID int
)
As

if ( @ObjectTypeID is NULL )
	set @ObjectTypeID = 0

Select ObjectID as ID , ObjectName as Name
from tb_Object tbl1
where tbl1.ObjectTypeID =
		 Case
			When @ObjectTypeID = 0 then tbl1.ObjectTypeID
			Else @ObjectTypeID
		 End
 and tbl1.Flag & 1 <> 1
GO
