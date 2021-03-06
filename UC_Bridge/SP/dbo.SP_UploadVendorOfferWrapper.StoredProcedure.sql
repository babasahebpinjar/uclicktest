USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UploadVendorOfferWrapper]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UploadVendorOfferWrapper]
(
	@UserID int
)
As


--------------------------------------------------------------------
-- Open a cursor and process through each of the offers that are in
-- Validated state
--------------------------------------------------------------------

Declare @VarOfferID int,
        @ResultFlag int,
		@ErrorDescription varchar(2000),
		@ErrorMsgStr varchar(2000),
		@PreferentialAutomationFlag int

--------------------------------------------------------------------------
-- Extract the value for the Preferential Automation from the TB_CONFIG
--------------------------------------------------------------------------

select @PreferentialAutomationFlag = ConfigValue
from tb_Config
where ConfigName = 'PreferentialAutomation'

if ( @PreferentialAutomationFlag is NULL )
      set @PreferentialAutomationFlag = 0

DECLARE db_Upload_VendorOffers_Cur CURSOR FOR  
select VendorOfferID
from TB_VendorOfferDetails tbl1
inner join TB_VendorReferenceDetails tbl2 on tbl1.Referenceid = tbl2.ReferenceID
where tbl1.OfferStatusID  = 3 -- Validated Status
and tbl2.AutoOfferUploadFlag = 1 -- Automatic offer upload
and tbl1.PartialOfferProcessFlag = 
    Case
		When @PreferentialAutomationFlag = 1 Then 0 -- Offer has been validated complete
		Else tbl1.PartialOfferProcessFlag
	End


OPEN db_Upload_VendorOffers_Cur   
FETCH NEXT FROM db_Upload_VendorOffers_Cur
INTO @VarOfferID 

WHILE @@FETCH_STATUS = 0   
BEGIN 

		--------------------------------------------------------------
		-- Need to check the offer audit history to establish if we 
		-- need to pass it for upload, or bypass it as it will be
		-- uploaded manually
		--------------------------------------------------------------

		if  (isnull(@PreferentialAutomationFlag , 0) = 1 )
		Begin

				if exists ( 
				             select 1 
							 from TB_VendorOfferDetails_Audit
							 where VendorOfferID = @VarOfferID
							 and OfferStatusID = 3
							 and PartialOfferProcessFlag = 1
						  )
				Begin
				 
						GOTO PROCESSNEXT

				End

		End



		Begin Try

				set @ResultFlag = 0
				set @ErrorDescription = NULL

				Exec SP_UploadVendorOffer @VarOfferID , 1 , @UserID,
									      @ResultFlag Output,
										  @ErrorDescription Output

		End Try

		Begin Catch

				set @ErrorMsgStr = 'ERROR !!! During Validation of offer with ID : ' + convert(varchar(20) ,  @VarOfferID) + '.' + ERROR_MESSAGE()

				RaisError('%s' , 16, 1 , @ErrorMsgStr)

				CLOSE db_Upload_VendorOffers_Cur  
				DEALLOCATE db_Upload_VendorOffers_Cur

				Return 1

		End Catch

PROCESSNEXT: 

		FETCH NEXT FROM db_Upload_VendorOffers_Cur
		INTO  @VarOfferID
 
END   

CLOSE db_Upload_VendorOffers_Cur  
DEALLOCATE db_Upload_VendorOffers_Cur

Return 0
GO
