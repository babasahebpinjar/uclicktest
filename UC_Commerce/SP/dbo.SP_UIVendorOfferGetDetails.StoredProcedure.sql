USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIVendorOfferGetDetails]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIVendorOfferGetDetails]
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

Declare @OfferStatusID int,
        @OfferStatus varchar(200),
		@ModifiedDate datetime,
		@ModifiedByID int



select @OfferStatusID = tbl1.OfferStatusID,
       @ModifiedDate = tbl1.ModifiedDate,
	   @ModifiedByID = tbl1.ModifiedByID,
	   @OfferStatus = tbl2.OfferStatus
from tb_OfferWorkflow tbl1
inner join tb_OfferStatus tbl2 on tbl1.OfferStatusID = tbl2.OfferStatusID
where offerID = @VendorOfferID
and tbl1.ModifiedDate = 
(
	select Max(ModifiedDate)
	from tb_OfferWorkflow 
	where OfferID = @VendorOfferID
)


--------------------------------------
-- Get details for the Vendor Offer
--------------------------------------

select offr.OfferID , offr.ExternalOfferFileName , offr.OfferFileName ,
       offr.OfferDate , offr.OfferContent , @OfferStatusID as OfferStatusID, @OfferStatus as OfferStatus,
	   @ModifiedDate as ModifiedDate , UC_Admin.dbo.FN_GetUserName(@ModifiedByID) as ModifiedByUser
from tb_Offer offr
inner join tb_source src on offr.SourceID = src.SourceID
where offr.offertypeid = -1
and offr.OfferID = @VendorOfferID

Return 0
GO
