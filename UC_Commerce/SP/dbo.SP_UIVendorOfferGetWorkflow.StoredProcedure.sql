USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIVendorOfferGetWorkflow]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIVendorOfferGetWorkflow]
(
	@VendorOfferID int,
	@ErrorDescription varchar(2000) output,
	@ResultFlag int output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0


------------------------------------------------------------------
-- Check to ensure that the Vendor OfferID is not null or invalid
------------------------------------------------------------------

if ( ( @VendorOfferID is Null) or not exists (select 1 from tb_Offer where OfferID = @VendorOfferID and OfferTypeID = -1) )
Begin

	set @ErrorDescription = 'ERROR !!!! Vendor Offer ID cannot be NULL or an invalid value'
	set @ResultFlag = 1
	return 1

End

-----------------------------------------------------------
--  Get the latest status and Modification stats from the
-- workflow table
-----------------------------------------------------------


select tbl1.OfferWorkflowID , tbl1.OfferStatusID , tbl2.OfferStatus,
       tbl1.ModifiedDate , UC_Admin.dbo.FN_GetUserName(tbl1.ModifiedByID) as ModifiedByUser
from tb_OfferWorkflow tbl1
inner join tb_OfferStatus tbl2 on tbl1.OfferStatusID = tbl2.OfferStatusID
where offerID = @VendorOfferID
order by tbl1.ModifiedDate 

Return 0
GO
