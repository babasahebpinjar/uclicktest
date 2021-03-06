USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSCreateExternalCustomerOfferFileName]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSCreateExternalCustomerOfferFileName]
(
	@OfferID int,
	@ExternalOfferFileName varchar(500) Output,
	@ResultFlag int output,
	@ErrorDescription varchar(2000) output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

-------------------------------------------------------------------------------
-- Check to see that the SourceID exists in the system and is not a NULL value
-------------------------------------------------------------------------------

if ( @OfferID is NULL )
Begin
		set @ErrorDescription = 'ERROR !!! OfferID passed cannot be NULL'
		set @ResultFlag = 1
		Return 1

End

if not exists ( select 1 from tb_offer where offerID = @OfferID and offertypeID = -2 ) -- Customer Offer
Begin

		set @ErrorDescription = 'ERROR !!! OfferID passed for the Customer offer does not exist in the system'
		set @ResultFlag = 1
		Return 1

End

-------------------------------------------------------------------
-- Check to ensure the previous status of the file. Only files
-- which have previous status as "Export Successful" qualify for 
-- anaysis and export
-------------------------------------------------------------------

Declare @PreviousOfferStatusID int

select @PreviousOfferStatusID = OfferStatusID
from tb_OfferWorkflow
where offerID = @OfferID
and ModifiedDate = 
(
	select max(ModifiedDate)
	from tb_OfferWorkflow
	where offerID = @OfferID
)

if ( @PreviousOfferStatusID != 16 )
Begin

		set @ErrorDescription = 'ERROR !!! Offer not eligible for external generation. Status of customer offer has to be "Export Successful"'
		set @ResultFlag = 1
		return 1

End

------------------------------------------------------
-- Build the name of the externaloffer file, from the
-- name of the Offer file name (.offr)
------------------------------------------------------

select @ExternalOfferFileName = replace(OfferFileName , '.offr' , '.xlsx')
from tb_Offer
where OfferID = @OfferID


Return 0

GO
