USE [UC_Operations]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIObjectInstanceGetDetails]    Script Date: 5/2/2020 6:25:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIObjectInstanceGetDetails]
(
	@ObjectInstanceID int
)
As

select oinst.ObjectInstanceID , oinst.ObjectInstance,
       obj.ObjectName, objType.ObjectTypeName,
	   st.statusID ,st.StatusName as Status,
	   oinst.StartDate , oinst.EndDate,
	   oinst.ProcessStartTime , oinst.ProcessEndTime,
	   oinst.Remarks, oinst.ModifiedDate,
	   usr.Name as ModifiedBy
from tb_ObjectInstance oinst
inner join tb_Object obj on oinst.ObjectID = obj.ObjectID
inner join tb_ObjectType objtype on obj.ObjectTypeID = objtype.ObjectTypeID
inner join tb_Status st on oinst.StatusID  = st.StatusID
inner join UC_Admin.dbo.tb_Users usr on oinst.ModifiedByID = usr.UserID
where oinst.ObjectInstanceID = @ObjectInstanceID

Return 0
GO
