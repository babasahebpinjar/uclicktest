USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIVendorOfferStatusTransitionUpdate]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UIVendorOfferStatusTransitionUpdate]
(
	@VendorOfferID int,
	@TargetOfferStatusID int,
	@UserID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
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
-- Get the latest status and Modification stats from the
-- workflow table
-----------------------------------------------------------

Declare @OfferStatusID int,
        @Offerstatus varchar(100),
		@TargetOfferstatus varchar(100)


select @Offerstatus = Offerstatus
from tb_OfferStatus
where OfferStatusID = @OfferStatusID
and offertypeId = -1

select @TargetOfferstatus = Offerstatus
from tb_OfferStatus
where OfferStatusID = @TargetOfferstatusID
and offertypeId = -1


select @OfferStatusID  = dbo.FN_GetVendorOfferCurrentStatus(@VendorOfferID)


-----------------------------------------------------------------
-- Check if there exists a transition from current offer status
-- to target offer status
-----------------------------------------------------------------

if not exists ( 
				select 1 from tb_OfferStatusTransition
                where offertypeID = -1 
				    and 
					   FromOfferStatusID = @OfferStatusID
					and
					   ToOfferStatusID = @TargetOfferStatusID
			   )
Begin

	set @ErrorDescription = 'ERROR !!!! No valid workflow transition exists from : ' + @Offerstatus + ' status to : ' + @TargetOfferstatus + ' status'
	set @ResultFlag = 1
	return 1
	
End

-----------------------------------------------------------
-- Add an entry to the offer workflow so that offer
-- has the new status updated
----------------------------------------------------------

Insert into tb_OfferWorkflow
(
	OfferID,
	OfferStatusID,
	ModifiedDate,
	ModifiedByID
)
Values
(
	@VendorOfferID,
	@TargetOfferStatusID ,
	getdate(),
	@UserID
)

Return 0
GO
