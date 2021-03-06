USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSUploadOfferFileWrapper]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSUploadOfferFileWrapper]
(
	@UserID int
)
As


------------------------------------------------
-- Get the list of files that are currently in 
-- Created state
------------------------------------------------

Create Table #TempUploadOfferFileList
(
	OfferID int,
	SourceID int,
	OfferDate datetime
)


insert into #TempUploadOfferFileList
(OfferID , SourceID , OfferDate)
Select offr.OfferID , offr.SourceID , offr.OfferDate
from tb_offer offr
inner join
(
		select tbl2.offerID
		from tb_OfferWorkflow tbl1
		inner join 
		(
			select offerID , Max(ModifiedDate) as ModifiedDate
			from tb_OfferWorkflow
			group by offerID
		) tbl2 on tbl1.OfferID = tbl2.OfferID and tbl1.ModifiedDate = tbl2.ModifiedDate
		where tbl1.OfferStatusID = 1 -- Created
) offr1 on offr.offerID = offr1.offerID
where offr.offertypeID = -1 -- Vendor Offer


--------------------------------------------------------------------
-- Open a cursor and process through each of the offers that are in
-- created state
--------------------------------------------------------------------

Declare @VarOfferID int,
        @ResultFlag int,
		@ErrorDescription varchar(2000),
		@ErrorMsgStr varchar(2000)

DECLARE db_Upload_VendorOffers_Cur CURSOR FOR  
select OfferID
From #TempUploadOfferFileList
order by OfferDate , SourceID


OPEN db_Upload_VendorOffers_Cur   
FETCH NEXT FROM db_Upload_VendorOffers_Cur
INTO @VarOfferID 

WHILE @@FETCH_STATUS = 0   
BEGIN  

		Begin Try

				set @ResultFlag = 0
				set @ErrorDescription = NULL

				Exec SP_BSUploadOfferFile @VarOfferID , @UserID,
				                          @ResultFlag Output,
										  @ErrorDescription Output

		End Try

		Begin Catch

				set @ErrorMsgStr = 'ERROR !!! During processing of offer with ID : ' + convert(varchar(20) ,  @VarOfferID) + '.' + ERROR_MESSAGE()

				RaisError('%s' , 16, 1 , @ErrorMsgStr)

				CLOSE db_Upload_VendorOffers_Cur  
				DEALLOCATE db_Upload_VendorOffers_Cur

				GOTO PROCESSEND

		End Catch


		FETCH NEXT FROM db_Upload_VendorOffers_Cur
		INTO  @VarOfferID 
 
END   

CLOSE db_Upload_VendorOffers_Cur  
DEALLOCATE db_Upload_VendorOffers_Cur


PROCESSEND:

-----------------------------------------------------
--  Drop all temporary tables post processing of data
-----------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempUploadOfferFileList') )
	Drop table #TempUploadOfferFileList
GO
