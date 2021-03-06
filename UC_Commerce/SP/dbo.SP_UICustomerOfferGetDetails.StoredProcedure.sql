USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICustomerOfferGetDetails]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_UICustomerOfferGetDetails]
(
	@CustomerOfferID int,
	@ErrorDescription varchar(2000) output,
	@ResultFlag int output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0


------------------------------------------------------------------
-- Check to ensure that the Vendor OfferID is not null or invalid
------------------------------------------------------------------

if ( ( @CustomerOfferID is Null) or not exists (select 1 from tb_Offer where OfferID = @CustomerOfferID and OfferTypeID = -2) )
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
where offerID = @CustomerOfferID
and tbl1.ModifiedDate = 
(
	select Max(ModifiedDate)
	from tb_OfferWorkflow 
	where OfferID = @CustomerOfferID
)


-------------------------------------------------------
-- Based on the status of the Offer, check if Customer
-- specific external offer file has been generated or not
--------------------------------------------------------

Declare @CustomerExternalOfferFile varchar(500) = NULL

if (@OfferStatusID = 16) -- 'Export Successful
Begin

		Exec SP_UIGetCustomerOfferFilePath @CustomerOfferID , 3 , @CustomerExternalOfferFile Output

End

------------------------------------------------
-- Extract just the name of the file from the 
-- Complete path
------------------------------------------------

if (@CustomerExternalOfferFile is not NULL)
     set @CustomerExternalOfferFile = reverse(substring(reverse(@CustomerExternalOfferFile) , 1 , charindex('\' ,reverse(@CustomerExternalOfferFile)) -1))


--------------------------------------
-- Get details for the Customer Offer
--------------------------------------

select offr.OfferID , offr.ExternalOfferFileName , offr.OfferFileName ,
       offr.OfferDate , offr.OfferContent , @OfferStatusID as OfferStatusID, @OfferStatus as OfferStatus,
	   @CustomerExternalOfferFile as CustomerExternalOffer,
	   @ModifiedDate as ModifiedDate , UC_Admin.dbo.FN_GetUserName(@ModifiedByID) as ModifiedByUser
from tb_Offer offr
inner join tb_source src on offr.SourceID = src.SourceID
where offr.offertypeid = -2
and offr.OfferID = @CustomerOfferID

Return 0
GO
