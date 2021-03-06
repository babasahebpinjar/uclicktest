USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_SendOffersProcessedDaily]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_SendOffersProcessedDaily]
(
	@Rundate datetime = NULL	
)

As

------------------------------------------------------------------------
-- If RunDate is NULL, then set the run date to current - 1 date
------------------------------------------------------------------------

if (@Rundate is NULL )
Begin

		set @Rundate = DateAdd(dd , -1 ,convert(date , getdate()) )

End


--------------------------------------------------------------
-- Declare essential variables for processing purposes
--------------------------------------------------------------

Declare @MessageStr varchar(max),
        @EmailAddress Varchar(2000),
		@SubjectLine Varchar(2000),
		@Attachment varchar(1000)

set @EmailAddress = 'nexwave_ccpl@ccplglobal.com;Daniel.see@ccplglobal.com' 


if not exists ( select 1 from TB_VendorOfferDetails where offerstatusid = 7 and  datediff(dd , convert(date ,offerprocessdate) , @Rundate ) = 0  )
Begin

		Return

End

set @SubjectLine = 'List of Offers Processed on : ' + convert(varchar(10) , @Rundate , 120 )

set @MessageStr = 'Published below are the details of offers processed. Please check if VMANAGE files have been generated for these offers.' +  '<br>' + '<br>'

print @SubjectLine

-------------------------------------------------------------------------
-- Open cursor to get details of all the offers that have been processed
-- on particular day
-------------------------------------------------------------------------

Declare @VendorOfferID int,
        @ReferenceNo varchar(100),
		@Account varchar(100),
		@OfferProcessDate datetime
		

DECLARE db_Check_Vmanage__VendorOffers_Cur CURSOR FOR  
select tbl1.VendorOfferID , tbl2.ReferenceNo , tbl2.Account , tbl1.OfferProcessDate
from TB_VendorOfferDetails tbl1
inner join TB_VendorReferenceDetails tbl2 on tbl1.Referenceid = tbl2.ReferenceID
where offerstatusid = 7 -- Processed
and datediff(dd , convert(date ,offerprocessdate) , @Rundate ) = 0

OPEN db_Check_Vmanage__VendorOffers_Cur   
FETCH NEXT FROM db_Check_Vmanage__VendorOffers_Cur
INTO  @VendorOfferID , @ReferenceNo , @Account , @OfferProcessDate 

WHILE @@FETCH_STATUS = 0   
BEGIN 

	
	
	    set @MessageStr = @MessageStr + '<b> Vendor Offer : </b>' + convert(varchar(20) , @VendorOfferID) + 
		              ' <b>' + '&nbsp;&nbsp;&nbsp;Offer Process Date : </b>' +  convert(varchar(20) , @OfferProcessDate , 120 ) +
	                  ' <b>' + '&nbsp;&nbsp;&nbsp;Reference No : </b>' + @ReferenceNo + '<br>'



		FETCH NEXT FROM db_Check_Vmanage__VendorOffers_Cur
		INTO  @VendorOfferID , @ReferenceNo , @Account , @OfferProcessDate
 
END   

CLOSE db_Check_Vmanage__VendorOffers_Cur  
DEALLOCATE db_Check_Vmanage__VendorOffers_Cur


----------------------------------------------------------------------------------
-- Call the procedure to send in the email alert for all the processed offers
----------------------------------------------------------------------------------

Exec SP_SendEmailAlerts @EmailAddress, @SubjectLine, @MessageStr , @Attachment



GO
