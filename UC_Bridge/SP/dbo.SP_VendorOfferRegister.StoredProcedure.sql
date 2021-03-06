USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_VendorOfferRegister]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_VendorOfferRegister]
( @ReferenceNo varchar(100) ,
  @OfferFileName varchar(500),
  @OfferReceiveDate datetime,
  @OfferType varchar(20),
  @ResponseFileName varchar(500),
  @VendorOfferID int output
)
--With Encryption 
As  

Declare @ReferenceID int,
        @ErrorMsgStr varchar(2000),
	@OfferTypeid int,
	@OfferStatus varchar(100)
        
        
----------------------------------------------------------
-- Check if the input parameters are NULL value or Not
----------------------------------------------------------

if ( @ReferenceNo is NULL )
Begin

     set @ErrorMsgStr = 'ReferenceID value is NULL. Please Check.'
     RaisError( '%s' , 16 , 1 , @ErrorMsgStr )
     return


End

if ( @OfferFileName is NULL )
Begin

     set @ErrorMsgStr = 'Offer File Name value is NULL. Please Check.'
     RaisError( '%s' , 16 , 1 , @ErrorMsgStr )
     return


End

if ( @OfferReceiveDate is NULL )
Begin

     set @ErrorMsgStr = 'Offer Receival Date value is NULL. Please Check.'
     RaisError( '%s' , 16 , 1 , @ErrorMsgStr )
     return


End

if ( @OfferType is NULL )
Begin

     set @ErrorMsgStr = 'Offer Type value is NULL. Please Check.'
     RaisError( '%s' , 16 , 1 , @ErrorMsgStr )
     return


End
Else
Begin

      if ( @OfferType not in ('AZ' , 'FC' , 'PR' ) )
      Begin
      
			 set @ErrorMsgStr = 'Offer Type value not Valid. Value should be AZ/FC/PR'
			 RaisError( '%s' , 16 , 1 , @ErrorMsgStr )
			 return      
      
      End

      Else
      Begin

			select @OfferTypeid = id
			from tbloffertype
			where code = @OfferType

      End


End


if ( @ResponseFileName is NULL )
Begin

     set @ErrorMsgStr = 'Response File Name is NULL. Please Check.'
     RaisError( '%s' , 16 , 1 , @ErrorMsgStr )
     return


End

if ( left(@ResponseFileName , 1) <> '"' )
   set @ResponseFileName  = '"' + @ResponseFileName  + '"'

   
-----------------------------------------------------------
-- Get the ReferenceID for the respective Reference No
-----------------------------------------------------------      

select @ReferenceID = referenceID
from TB_VendorReferenceDetails
where referenceno = @ReferenceNo

if (@ReferenceID is null )
Begin

     set @ErrorMsgStr = 'ReferenceNo : ' + @ReferenceNo + ' does not exist in repository'
     RaisError( '%s' , 16 , 1 , @ErrorMsgStr )
     return

End

--------------------------------------------------------------
-- Check if file registration record already exists or not
--------------------------------------------------------------

if exists (
             select 1
             from tb_vendorofferdetails
             where referenceid = @ReferenceID
             and OfferFileName = @OfferFileName
             and OfferReceiveDate = @OfferReceiveDate
             and OfferType =  @OfferType
             and offerstatus = 'Registered'
          )
Begin

     set @ErrorMsgStr = 'Error !!!Duplicate Registration of the vendor offer file.'
     RaisError( '%s' , 16 , 1 , @ErrorMsgStr )
     return
     
End    


select @OfferStatus = OfferStatus
from tb_OfferStatus
where offerstatusid = 1

------------------------------------------------------
-- Insert record into the tb_vendorofferdetails table
------------------------------------------------------

Begin Try

insert into tb_vendorofferdetails
(
   Referenceid,
   OfferFileName,
   LoadOfferName,
   OfferReceiveDate,
   OfferType,
   OfferTypeID,
   UploadOfferType,
   OfferProcessDate,
   OfferStatus,
   OfferStatusID,
   AcknowledgementSend,
   ProcessedStatusSend,
   PartialOfferProcessFlag
)
values
(
  @ReferenceID,
  @OfferFileName,
  Null,
  @OfferReceiveDate,
  @OfferType,
  @OfferTypeID,
  NULL,
  NULL,
  @OfferStatus,
  1, -- 'Registered'
  'N',
  'N',
   NULL
)

End Try

Begin Catch

     set @ErrorMsgStr = 'Error !!!Cannot insert record into database.'+ERROR_MESSAGE()
     RaisError( '%s' , 16 , 1 , @ErrorMsgStr )
     return
     

End Catch


select @VendorOfferID = vendorofferid
from TB_VendorOfferDetails
where referenceid = @ReferenceID
and offerfilename = @OfferFileName
and offerreceivedate = @OfferReceiveDate
and offertypeid = @OfferTypeid
and offerstatusid = 1

------------------------------------------------------------------
-- Update the AcknowledgementSend flag of the vendor offer, post
-- successfull registration and response generation.
------------------------------------------------------------------

update TB_VendorOfferDetails
set AcknowledgementSend = 'Y'
where vendorofferid = @VendorOfferID
GO
