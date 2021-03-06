USE [UC_Operations]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIObjectTypeStatusList]    Script Date: 5/2/2020 6:25:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIObjectTypeStatusList]
(
	@ObjectTypeID int =  NULL
)
As


Declare @ObjectTypeIDStr varchar(10)

if ( @ObjectTypeID = 0 or @ObjectTypeID is NULL )
Begin

		select statusID as ID , StatusName as Name
		from tb_Status
		Where flag & 1 <> 1
		order by statusid

End 

Else
Begin

		select st.statusid as ID , st.Statusname as Name
		from tb_Status st
		inner join tb_ObjectTypeStatus ots on st.statusid = ots.statusid
		inner join tb_ObjectType ot on ots.ObjectTypeID = ot.ObjectTypeID
		Where ot.ObjectTypeID = @ObjectTypeID
		and st.flag & 1 <> 1
		and ots.flag & 1 <> 1
		order by st.statusid

End

Return 0

GO
