USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIValidateVendorOfferTestMode]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIValidateVendorOfferTestMode]
(
   @VendorOfferID int,
   @UserID int,
   @ResultFlag int output,
   @ErrorDescription varchar(2000) output
)
--With Encryption 
As

set @ResultFlag  = 0
set @ErrorDescription = NULL

Declare	@ReturnFlag int,
		@ErrorMessage varchar(2000)

if not exists ( select 1 from tb_vendorofferdetails where vendorofferid = @VendorOfferID )
Begin

	set @ResultFlag = 1
	set @ErrorDescription = 'Vendor Offer with the ID : ' + convert(varchar(20) , @VendorOfferID) + ' does not exist in system'
	Return 1

End

------------------------------------------------------
-- Check if the logged in user is authorized to
-- Change offer status via workflow
------------------------------------------------------

Exec SP_UICheckUserPrivilegeRole @UserID , 'Edit VendorOffers' , @ReturnFlag output

if (@ReturnFlag = 0)
Begin

	set @ErrorDescription = 'Logged User does not have privilege to run validation on vendor offers in test mode'
	set @ResultFlag = 1
	return 1

End



------------------------------------------
-- Actual piece of code, post deployment
------------------------------------------
set @ReturnFlag = 0
Exec SP_ValidateVendorOfferContent @VendorOfferID , 0 , @UserID, @ReturnFlag Output , @ErrorMessage output

if ( @ReturnFlag = 1 )
Begin

	set @ResultFlag = 1
	set @ErrorDescription = @ErrorMessage

	return 1

End


Return
GO
