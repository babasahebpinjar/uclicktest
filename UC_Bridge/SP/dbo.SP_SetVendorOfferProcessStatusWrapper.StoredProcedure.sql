USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_SetVendorOfferProcessStatusWrapper]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_SetVendorOfferProcessStatusWrapper]
(
	@UserID int
)
As


--------------------------------------------------------------------
-- Open a cursor and process through each of the offers that are in
-- Processing state
--------------------------------------------------------------------

Declare @VarOfferID int,
        @ResultFlag int,
		@ErrorDescription varchar(2000),
		@ErrorMsgStr varchar(2000)

DECLARE db_SetProcessing_VendorOffers_Cur CURSOR FOR  
select VendorOfferID
from TB_VendorOfferDetails
where OfferStatusID  = 6 -- Processing Status


OPEN db_SetProcessing_VendorOffers_Cur   
FETCH NEXT FROM db_SetProcessing_VendorOffers_Cur
INTO @VarOfferID 

WHILE @@FETCH_STATUS = 0   
BEGIN 

       ------------------------------------------------------
	   -- Check to ensure that there are no offers before 
	   -- this offer which are pending Export into the
	   -- system
	   ------------------------------------------------------

		Begin Try

				set @ResultFlag = 0
				set @ErrorDescription = NULL

				Exec SP_SetVendorOfferProcessStatus @VarOfferID , @UserID,
												  @ResultFlag Output,
												  @ErrorDescription Output

		End Try

		Begin Catch

				set @ErrorMsgStr = 'ERROR !!! During processing of offer with ID : ' + convert(varchar(20) ,  @VarOfferID) + '.' + ERROR_MESSAGE()

				RaisError('%s' , 16, 1 , @ErrorMsgStr)

				CLOSE db_SetProcessing_VendorOffers_Cur  
				DEALLOCATE db_SetProcessing_VendorOffers_Cur

				Return 1

		End Catch

--

		FETCH NEXT FROM db_SetProcessing_VendorOffers_Cur
		INTO  @VarOfferID
 
END   

CLOSE db_SetProcessing_VendorOffers_Cur  
DEALLOCATE db_SetProcessing_VendorOffers_Cur

Return 0
GO
