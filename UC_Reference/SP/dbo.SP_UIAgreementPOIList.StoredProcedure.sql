USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIAgreementPOIList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIAgreementPOIList]
(
	@AgreementID int,
	@SelectDate DateTime = NULL
)
As

if (@SelectDate is not NULL)
Begin

		Select tbl1.AgreementPOIID , tbl1.AgreementID, 
			   tbl1.trunkID , tbl2.Trunk,
			   tbl1.DirectionID , tbl3.Direction,
			   tbl1.BeginDate , tbl1.EndDate,
			   tbl1.ModifiedDate,
			   uc_Admin.dbo.FN_GetUserName(tbl1.ModifiedByID) as ModifiedUserID
		from tb_agreementPOI tbl1
		inner join tb_trunk tbl2 on tbl1.TrunkID = tbl2.TrunkID
		inner join tb_Direction tbl3 on tbl1.directionId = tbl3.DirectionID
		where tbl1.AgreementID = @AgreementID
		and @SelectDate between tbl1.BeginDate and isnull(tbl1.EndDate , @SelectDate)
		and tbl1.flag & 1 <> 1

End

Else
Begin

		Select tbl1.AgreementPOIID , tbl1.AgreementID, 
			   tbl1.trunkID , tbl2.Trunk,
			   tbl1.DirectionID , tbl3.Direction,
			   tbl1.BeginDate , tbl1.EndDate,
			   tbl1.ModifiedDate,
			   uc_Admin.dbo.FN_GetUserName(tbl1.ModifiedByID) as ModifiedUserID
		from tb_agreementPOI tbl1
		inner join tb_trunk tbl2 on tbl1.TrunkID = tbl2.TrunkID
		inner join tb_Direction tbl3 on tbl1.directionId = tbl3.DirectionID
		where tbl1.AgreementID = @AgreementID
		and tbl1.flag & 1 <> 1

End
       
GO
