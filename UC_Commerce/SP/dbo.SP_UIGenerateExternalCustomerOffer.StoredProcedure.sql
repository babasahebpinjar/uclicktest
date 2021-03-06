USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGenerateExternalCustomerOffer]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGenerateExternalCustomerOffer]
(
	@OfferID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

---------------------------------------------------
-- Check to confirm that the offerID is not NULL
---------------------------------------------------

if ( @OfferID is NULL )
Begin
		set @ErrorDescription = 'ERROR !!! OfferID passed cannot be NULL'
		set @ResultFlag = 1
		GOTO PROCESSEND

End

if not exists ( select 1 from tb_offer where offerID = @OfferID and offertypeID = -2 ) -- Customer Offer
Begin

		set @ErrorDescription = 'ERROR !!! OfferID passed for the Customer offer does not exist in the system'
		set @ResultFlag = 1
		GOTO PROCESSEND

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
		GOTO PROCESSEND

End

---------------------------------------------------
-- Load the data for offer from upload tables into
-- temp tables
---------------------------------------------------

--------------------------
-- Destination Table
--------------------------

 if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempUploadDestination') )
 drop table #TempUploadDestination

select *
into #TempUploadDestination
from tb_UploadDestination
where offerID = @OfferID

--------------------------
-- Rate  Table
--------------------------

 if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempUploadRate') )
 drop table #TempUploadRate 
 
select *
into #TempUploadRate
from tb_UploadRate
where offerID = @OfferID

--------------------------
-- Dialed Digit Table
--------------------------

 if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempUploadBreakout') )
 drop table #TempUploadBreakout
 
select *
into #TempUploadBreakout
from tb_UploadBreakout
where offerID = @OfferID


------------------------------------------------------------------
-- Prepare the Final data content to be send to the program
-- that will generate the customer offer in the desired format
-------------------------------------------------------------------

Begin Try

		select dest.Destination , convert(date ,dest.EffectiveDate) as EffectiveDate  , dd.DialedDigit , rt.Rate , rm.RatingMethod , rdb.RateDimensionBand as TimeOfDay,      
			   Case
					When rt.AmountChange is NULL then 'New'
					When rt.AmountChange = 0 then 'Same'
					When rt.AmountChange > 0 then 'Increase'
					When rt.AmountChange < 0 then 'Decrease'
			   End as RateChange
		from #TempUploadDestination dest
		inner join #TempUploadBreakout dd on dest.UploadDestinationID = dd.UploadDestinationID
		inner join UC_Reference.dbo.tb_RatingMethod rm on dest.RatingMethodID = rm.RatingMethodID
		inner join #TempUploadRate rt on dest.UploadDestinationID = rt.UploadDestinationID
		inner join UC_Reference.dbo.tb_RateNumberIdentifier rni  on dest.ratingmethodid = rni.ratingmethodid
																  and
																	rt.RateTypeID = rni.RateItemID
		inner join UC_Reference.dbo.tb_RateDimensionBand rdb on rni.RateDimension1BandID = rdb.RateDimensionBandID
		order by dest.EffectiveDate , dest.Destination

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!! While generating external offer. ' + ERROR_MESSAGE()
		set @ResultFlag = 1
		GOTO PROCESSEND

End Catch


PROCESSEND:

 if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempUploadDestination') )
 drop table #TempUploadDestination

 if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempUploadRate') )
 drop table #TempUploadRate 

 if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempUploadBreakout') )
 drop table #TempUploadBreakout

GO
