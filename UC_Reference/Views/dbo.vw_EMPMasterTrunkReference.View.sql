USE [UC_Reference]
GO
/****** Object:  View [dbo].[vw_EMPMasterTrunkReference]    Script Date: 5/2/2020 6:27:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create View [dbo].[vw_EMPMasterTrunkReference]
As

select tbl3.Account , tbl4.Trunk as 'Carrier Code' , tbl1.Trunk ,  tbl5.Direction , tbl2.EffectiveDate , tbl6.ActiveStatus as Status ,
       tbl7.TransmissionType , tbl8.TrunkType
from tb_Trunk tbl1
inner join tb_TrunkDetail tbl2 on tbl1.TrunkId = tbl2.TrunkID
inner join tb_Account tbl3 on tbl1.AccountID = tbl3.AccountID   
left join tb_Trunk tbl4 on tbl2.CommercialTrunkID = tbl4.TrunkID
inner join tb_Direction tbl5 on tbl2.DirectionID = tbl5.DirectionID
inner join tb_ActiveStatus tbl6 on tbl2.ActiveStatusID = tbl6.ActiveStatusID
left join tb_Transmissiontype tbl7 on tbl1.TransmissionTypeID = tbl7.TransmissionTypeID
inner join tb_Trunktype tbl8 on tbl1.TrunkTypeID = tbl8.TrunkTypeID
where tbl1.TrunktypeID <> 9
GO
