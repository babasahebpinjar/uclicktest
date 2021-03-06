USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIUpdateOfferStatusViaWorkFlow]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_UIUpdateOfferStatusViaWorkFlow]
(

	@VendorOfferID int,
	@NewOfferStatusID int,
	@UserID int,
	@ResultFlag int output,
	@ErrorDescription varchar(2000) output
)
--With Encryption
As

set @ResultFlag = 0

Declare @OfferStatusID int,
        @OfferStatus varchar(50),
		@NewOfferStatus varchar(50),
		@ReturnFlag int,
		@ErrorMessage varchar(2000)


------------------------------------------------------
-- Check if the logged in user is authorized to
-- Change offer status via workflow
------------------------------------------------------

Exec SP_UICheckUserPrivilegeRole @UserID , 'Edit VendorOffers' , @ReturnFlag output

if (@ReturnFlag = 0)
Begin

	set @ErrorDescription = 'Logged User does not have privilege to change status of vendor offers'
	set @ResultFlag = 1
	return

End


Select @OfferStatusID = offerstatusid
from tb_vendorofferdetails
where vendorofferid = @VendorOfferID

select @OfferStatus = offerstatus
from tb_offerstatus
where offerstatusid = @OfferStatusID

select @NewOfferStatus = offerstatus
from tb_offerstatus
where offerstatusid = @NewOfferStatusID



if not exists ( select 1 from tb_offerstatusworkflow where FromVendorOfferStatusID = @OfferStatusID and ToVendorOfferStatusID = @NewOfferStatusID )
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Workflow does not allow to change offer status from ' + @OfferStatus + ' to ' +  @NewOfferStatus
	return

End


---------------------------------------------------------
-- Do a direct update in case of one of the following 
-- new statuses:
-- Registered
-- Suspended
-- Dispute
-- Rejected
---------------------------------------------------------

if ( @NewOfferStatusID in (1, 9 , 11 ,12) )
Begin

	update tb_vendorofferdetails
	set offerstatus = @NewOfferStatus,
	    offerstatusid = @NewOfferStatusID,
            modifieddate = getdate(),
	    modifiedbyID = @UserID
	where vendorofferid = @VendorOfferID

End

-------------------------------------------------------------
-- If the new status is Validating, then call the procedure
-- to validate the offer in Real Mode
-------------------------------------------------------------

if (  @NewOfferStatusID  = 2)
Begin

    ------------------------------------------
	-- Actual piece of code, post deployment
	------------------------------------------

	set @ReturnFlag = 0

	Exec SP_ValidateVendorOfferContent @VendorOfferID , 1 , @UserID, @ReturnFlag Output , @ErrorMessage output

	if ( @ReturnFlag = 1 )
	Begin

		set @ResultFlag = 1
		set @ErrorDescription = @ErrorMessage
		return

	End

	-------------------------------------
	-- Dummy piece of code for testing
	-------------------------------------
	--update tb_vendorofferdetails
	--set offerstatus = @NewOfferStatus,
	 --   offerstatusid = @NewOfferStatusID
         --   modifieddate = getdate(),
	 --   modifiedbyID = @UserID
	--where vendorofferid = @VendorOfferID


End


--------------------------------------------------------
-- Handle the Processing status in the following manner:
-- 1. Upload Error --> Processing
-- 2. Validated --> Processing
--------------------------------------------------------

if ( @NewOfferStatusID  = 6)
Begin

		if (@OfferStatusID = 3) -- Validated
		Begin

			------------------------------------------
			-- Actual piece of code, post deployment
			------------------------------------------

			set @ReturnFlag = 0
			Exec SP_UploadVendorOffer @VendorOfferID , 1 , @UserID ,@ErrorMessage output , @ReturnFlag Output

			if ( @ReturnFlag = 1 )
			Begin

				set @ResultFlag = 1
				set @ErrorDescription = @ErrorMessage

				return

			End

            -------------------------
			-- START DUMMY CODE
			-------------------------
			-------------------------------------
			-- Dummy piece of code for testing
			-------------------------------------
			--update tb_vendorofferdetails
			--set offerstatus = @NewOfferStatus,
			--    offerstatusid = @NewOfferStatusID,
			--    modifieddate = getdate(),
   --	                    modifiedbyID = @UserID
			--where vendorofferid = @VendorOfferID

			-----------------------------------------------
			---- Wait for 10 seconds and then change offer
			---- status to processed.
			-----------------------------------------------

			--WaitFor Delay '00:00:10'

			--update tb_vendorofferdetails
			--set offerstatus = case when PartialOfferProcessFlag = 1 then 'Partially Processed' Else 'Processed' end,
			--offerstatusid = case when PartialOfferProcessFlag = 1 then 8 Else 7 end,
			--    offerprocessdate = getdate(),
			--    LoadOfferName = replace(replace(replace(CONVERT(varchar(20) , getdate() , 120), '-' , ''),':' , ''), ' ', '')+ '_' + uploadoffertype+ + '.xls',
			--    modifieddate = getdate(),
			--    modifiedbyID = @UserID
			--where vendorofferid = @VendorOfferID

            -------------------------
			-- END DUMMY CODE
			-------------------------

		End

		Else
		Begin

			update tb_vendorofferdetails
			set offerstatus = @NewOfferStatus,
			    offerstatusid = @NewOfferStatusID,
			    modifieddate = getdate(),
			    modifiedbyID = @UserID
			where vendorofferid = @VendorOfferID


		End

End


Return
GO
