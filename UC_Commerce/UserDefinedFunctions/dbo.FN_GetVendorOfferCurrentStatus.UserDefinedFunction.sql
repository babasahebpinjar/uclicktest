USE [UC_Commerce]
GO
/****** Object:  UserDefinedFunction [dbo].[FN_GetVendorOfferCurrentStatus]    Script Date: 5/2/2020 6:19:37 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Function [dbo].[FN_GetVendorOfferCurrentStatus]
(
	@OfferID int
)
Returns INT As

Begin


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


Return @PreviousOfferStatusID


End
GO
