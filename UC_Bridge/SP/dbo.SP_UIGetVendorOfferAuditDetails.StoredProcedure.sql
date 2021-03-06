USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetVendorOfferAuditDetails]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetVendorOfferAuditDetails]
(
     @VendorOfferID int
)
--With Encryption
As


select tbl1.DMLAction as Action , tbl1.VendorOfferID , tbl2.ReferenceNo , tbl1.OfferFileName , tbl1.LoadOfferName, tbl1.OfferReceiveDate,
       tbl3.Code as OfferTypename, tbl1.OfferProcessDate , tbl4.OfferStatus , tbl1.AcknowledgementSend,
       tbl1.ProcessedStatusSend, tbl5.Code as UploadOfferTypename, tbl1.PartialOfferProcessflag, tbl1.ValidatedOfferFileName,
       tbl1.ModifiedDate , tbl6.Name as ModifiedBy
from tb_vendorofferdetails_audit tbl1
inner join tb_vendorReferenceDetails tbl2 on tbl1.ReferenceID = tbl2.ReferenceID
inner join tbloffertype tbl3 on tbl1.offertypeid = tbl3.ID
inner join tb_offerStatus tbl4 on tbl1.OfferStatusID = tbl4.OfferStatusID
left  join tbloffertype tbl5 on tbl1.uploadoffertypeid = tbl5.ID
left join tb_users tbl6 on tbl1.modifiedbyid = tbl6.userid
where tbl1.VendorOfferID = @VendorOfferID






GO
