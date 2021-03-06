USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICustomerOfferStatusTransition]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Procedure [dbo].[SP_UICustomerOfferStatusTransition]
(
	@CustomerOfferID int
)
As

select tbl3.OfferStatusID , tbl3.OfferStatus
from tb_OfferstatusTransition tbl1
inner join tb_Offerstatus tbl2 on tbl1.FromOfferStatusID = tbl2.OfferStatusID
inner join tb_Offerstatus tbl3 on tbl1.ToOfferStatusID = tbl3.OfferStatusID
where tbl1.OffertypeID = -2
and tbl1.FromOfferStatusID = dbo.FN_GetVendorOfferCurrentStatus(@CustomerOfferID)

Return 0
GO
