USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIAssociatedVendorOffersToSource]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_UIAssociatedVendorOffersToSource]
(
	@SourceID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As


----------------------------------------------------------------
-- Check if the Source ID is not NULL and exists in the system
----------------------------------------------------------------

if (@SourceID is NULL)
Begin

		set @ErrorDescription = 'ERROR !!! Source ID cannot be NULL'
		set @ResultFlag = 1
		Return 1

End


if not exists ( select 1 from tb_Source where sourceID = @SourceID and SourceTypeID = -1 )
Begin

		set @ErrorDescription = 'ERROR !!! Source ID does not exist or is an invalid value'
		set @ResultFlag = 1
		Return 1

End

--------------------------------------------------------------
-- Get all the offers associated with the vendor Source with
-- essential details
--------------------------------------------------------------

select offr.OfferID , offr.ExternalOfferFileName , offr.OfferFileName ,
       offr.OfferDate , offr.OfferContent , offrst.OfferStatusID , offrst.OfferStatus
from tb_Offer offr
inner join tb_OfferStatus offrst on dbo.FN_GetVendorOfferCurrentStatus(offr.OfferID) = offrst.OfferStatusID
                                    and offr.OfferTypeID = offrst.OfferTypeID
where offr.offertypeid = -1
and sourceID = @SourceID
order by offr.OfferDate desc


Return 0
GO
