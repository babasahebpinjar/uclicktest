USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSAnalyseAndExportCustomerOfferWrapper]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSAnalyseAndExportCustomerOfferWrapper]
(
	@UserID int
)
As


------------------------------------------------
-- Get the list of files that are currently in 
-- Created state
------------------------------------------------

Create Table #TempAnalyseAndExportOfferList
(
	OfferID int,
	SourceID int,
	OfferDate datetime
)


insert into #TempAnalyseAndExportOfferList
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
		where tbl1.OfferStatusID = 14 -- Created
) offr1 on offr.offerID = offr1.offerID
where offr.offertypeID = -2 -- Customer Offer


--------------------------------------------------------------------
-- Open a cursor and process through each of the offers that are in
-- created state
--------------------------------------------------------------------

Declare @VarOfferID int,
		@VarSourceID int,
		@VarOfferDate datetime,
        @ResultFlag int,
		@ErrorDescription varchar(2000),
		@ErrorMsgStr varchar(2000)

DECLARE db_AnalyzeAndExport_VendorOffers_Cur CURSOR FOR  
select OfferID , SourceID , OfferDate
From #TempAnalyseAndExportOfferList
order by OfferDate , SourceID


OPEN db_AnalyzeAndExport_VendorOffers_Cur   
FETCH NEXT FROM db_AnalyzeAndExport_VendorOffers_Cur
INTO @VarOfferID , @VarSourceID , @VarOfferDate

WHILE @@FETCH_STATUS = 0   
BEGIN 

       ------------------------------------------------------
	   -- Check to ensure that there are no offers before 
	   -- this offer which are pending Export into the
	   -- system
	   ------------------------------------------------------

	   if exists (	   
						select 1
						from tb_OfferWorkflow tbl1
						inner join 
						(
							select offfrwf.offerID , Max(offfrwf.ModifiedDate) as ModifiedDate
							from tb_OfferWorkflow offfrwf
							inner join tb_offer offr on offfrwf.OfferID = offr.OfferID
							Where offr.SourceID = @VarSourceID
							and offr.OfferID <> @VarOfferID
							and offr.offerdate < @VarOfferDate 
							group by offfrwf.offerID
						) tbl2 on tbl1.OfferID = tbl2.OfferID and tbl1.ModifiedDate = tbl2.ModifiedDate
						where tbl1.OfferStatusID <> 16 -- Export Successful	  
				 )
		Begin
		
				GOTO PROCESSNEXTREC

		End  

		Begin Try

				set @ResultFlag = 0
				set @ErrorDescription = NULL

				Exec SP_BSAnalyseAndExportCustomerOffer @VarOfferID , @UserID,
												  @ResultFlag Output,
												  @ErrorDescription Output

		End Try

		Begin Catch

				set @ErrorMsgStr = 'ERROR !!! During processing of offer with ID : ' + convert(varchar(20) ,  @VarOfferID) + '.' + ERROR_MESSAGE()

				RaisError('%s' , 16, 1 , @ErrorMsgStr)

				CLOSE db_AnalyzeAndExport_VendorOffers_Cur  
				DEALLOCATE db_AnalyzeAndExport_VendorOffers_Cur

				GOTO PROCESSEND

		End Catch

PROCESSNEXTREC:

		FETCH NEXT FROM db_AnalyzeAndExport_VendorOffers_Cur
		INTO  @VarOfferID , @VarSourceID , @VarOfferDate
 
END   

CLOSE db_AnalyzeAndExport_VendorOffers_Cur  
DEALLOCATE db_AnalyzeAndExport_VendorOffers_Cur


PROCESSEND:

-----------------------------------------------------
--  Drop all temporary tables post processing of data
-----------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAnalyseAndExportOfferList') )
	Drop table #TempAnalyseAndExportOfferList
GO
