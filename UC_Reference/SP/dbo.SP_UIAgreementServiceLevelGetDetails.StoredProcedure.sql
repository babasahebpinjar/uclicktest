USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIAgreementServiceLevelGetDetails]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  Procedure [dbo].[SP_UIAgreementServiceLevelGetDetails]
(
	@AgreementSLID int
)
As

Select tbl1.AgreementSLID , tbl1.AgreementID, 
	   tbl1.trunkID , tbl2.Trunk,
       tbl1.DirectionID , tbl3.Direction,
	   tbl1.DestinationID , Case When tbl1.DestinationID is NULL then 'All Destinations' Else tbl5.Destination End as Destination,
	   tbl1.ServiceLevelID , tbl4.ServiceLevel,
	   tbl1.BeginDate , tbl1.EndDate,
	   tbl1.ModifiedDate,
	   uc_Admin.dbo.FN_GetUserName(tbl1.ModifiedByID) as ModifiedUserID
from tb_agreementSL tbl1
inner join tb_trunk tbl2 on tbl1.TrunkID = tbl2.TrunkID
inner join tb_Direction tbl3 on tbl1.directionId = tbl3.DirectionID
inner join tb_serviceLevel tbl4 on tbl1.ServiceLevelID = tbl4.ServiceLevelID
left join tb_Destination tbl5 on tbl1.DestinationID = tbl5.DestinationID
where tbl1.AgreementSLID = @AgreementSLID
and tbl1.flag & 1 <> 1
       
GO
