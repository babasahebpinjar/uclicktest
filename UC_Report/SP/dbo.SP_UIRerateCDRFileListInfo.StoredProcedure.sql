USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRerateCDRFileListInfo]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRerateCDRFileListInfo]
(
	@RerateID int
)
As

select tbl1.CDRFIleID as CDRfileID, tbl2.ObjectInstance as CDRFileName , tbl2.StatusName as Status
from tb_RerateCDRFileList tbl1
inner join 
(
	Select objinst.ObjectInstanceID , objinst.ObjectInstance , st.StatusName
	from ReferenceServer.UC_Operations.dbo.tb_ObjectInstance objinst
	inner join ReferenceServer.UC_Operations.dbo.tb_Object obj on objinst.objectid = obj.ObjectID
	inner join ReferenceServer.UC_Operations.dbo.tb_status st on objinst.statusid = st.statusid
	where obj.ObjectTypeID = 100 --  CDR File Object
) tbl2 on tbl1.CDRFileID = tbl2.ObjectInstanceID
where tbl1.RerateID = @RerateID

Return 0


GO
