USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetStatusTransitionListWorkflow]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetStatusTransitionListWorkflow]
(
    @VendorOfferID int
)
--With Encryption
As

Declare @OfferStatusID int

Select @OfferStatusID = OfferStatusID
from tb_vendorOfferDetails
where vendorofferID = @VendorOfferID

--------------------------------------------------
-- Get the next list of status to transition
--------------------------------------------------

Select tbl1.ToVendorOfferStatusID as OfferstatusID, tbl2.OfferStatus 
from tb_OfferStatusWorkFlow tbl1 
inner join tb_OfferStatus tbl2 on tbl1.ToVendorOfferStatusID = tbl2.OfferStatusID
where fromVendorOfferStatusID = @OfferStatusID
and transitionflag = 1
order by tbl2.OfferStatus 
GO
