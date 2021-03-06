USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSUploadReferenceAnalyzeRates]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSUploadReferenceAnalyzeRates]
(
	@OfferID int,
	@UserID int
)
As

Declare @SourceID int,
		@OfferDate DateTime,
		@OfferContent varchar(50),
		@NumberPlanID int,
		@RatePlanID int,
		@CalltypeID int,
		@ExpireEffectiveDateAZFlag int

------------------------------------------------
-- Get essential attributes for the offer
------------------------------------------------

select @SourceID = SourceID,
       @OfferDate = OfferDate,
	   @OfferContent = OfferContent
from tb_Offer
where OfferID = @OfferID


Select @NumberPlanID = NumberplanID
from UC_Reference.dbo.tb_NumberPlan
where ExternalCode = @SourceID

select @RatePlanID = RatePlanID,
       @CallTypeID = CallTypeID
from tb_Source
where sourceID = @SourceID
  

----------------------------------------------------
-- Create temporary tables to store the data for
-- processing
----------------------------------------------------

--------------------------------------------
-- Table to store all the offer rates to be
-- uploaded
--------------------------------------------

Create table #IncomingOfferRates
(
	[UploadRateID] [int] ,
	[UploadDestinationID] [int] NOT NULL,
	[DestinationID] [int] NOT NULL,
	[Rate] [decimal](19, 6) NOT NULL,
	[RatingMethodID] int NOT NULL ,
	[RateTypeID] [int] NOT NULL,
	[EffectiveDate] [datetime] NOT NULL,
	[PrevRate] [decimal](19, 6) NULL,
	[AmountChange] [decimal](19, 6) NULL,
	[PrevBeginDate] [datetime] NULL,
	[Flag] [int] NOT NULL
)


-----------------------------------------------------
-- Create table to store all the previous rates for 
-- qualified rates from incoming offer
-----------------------------------------------------

Create Table #PreviousExistingRates
(
	RateID int,
	DestinationID int,
	CallTypeID int,
	RatingMethodID int,
	Rate Decimal(19,6),
	BeginDate Date,
	EndDate Date,
	RateTypeID int
)

-----------------------------------------------------------
-- Open a cursor for each effective date supplied in the
-- offer and process rates for this date
-----------------------------------------------------------

Declare @VarEffectiveDate Date

Declare UploadReferenceRates_Cur Cursor For
select Distinct AnalysisDate
from #TempUploadDestination
order by AnalysisDate

Open UploadReferenceRates_Cur
Fetch Next From UploadReferenceRates_Cur
Into @VarEffectiveDate

While @@FETCH_STATUS = 0
Begin

	Delete from #IncomingOfferRates
	Delete from #PreviousExistingRates

    insert into #IncomingOfferRates
	(
		[UploadRateID] ,
		[UploadDestinationID] ,
		[DestinationID],
		[RatingMethodID],
		[Rate] ,
		[RateTypeID],
		[EffectiveDate],
		[Flag]
	)
	select tbl1.RateAnalysisSummaryID , tbl1.RateAnalysisID , tbl2.RefDestinationID, tbl2.RatingMethodID,
	       tbl1.AnalyzedRate, tbl1.RateTypeID , tbl2.AnalysisDate , 0
	from #TempUploadRate tbl1
	inner join #TempUploadDestination tbl2 on tbl1.RateAnalysisID = tbl2.RateAnalysisID
	where tbl2.AnalysisDate = @VarEffectiveDate

	--------------------
	-- Debugging Start
	--------------------

	select 'Incoming Rate' , *
	from #IncomingOfferRates
	
	---------------------
	-- Debugging End
	---------------------

	-----------------------------------------------------------------------------
	-- Mark all the following records for deletion in the rates table
	-- 1. All pre-existing records having Begin Date greater than the upload Rate
	-- 2. All Records having the same effective date but unequal rates
	-- 3. All records having same Effective date but different rating method
	------------------------------------------------------------------------------

	update rt
	set rt.Flag = rt.flag | 1 -- Mark the records for deletion
	from UC_Reference.dbo.tb_Rate rt
	inner join UC_Reference.dbo.tb_RateDetail rtd on rt.rateID = rtd.RateID
	inner join #IncomingOfferRates irt on rt.DestinationID = irt.DestinationID
	where rt.RatePlanID = @RatePlanID
	and rt.CallTypeID = @CalltypeID
	and
	(
		rt.BeginDate > irt.EffectiveDate
		or
		(rt.BeginDate = irt.EffectiveDate and rtd.Rate <> irt.Rate)
		or
		(rt.BeginDate = irt.EffectiveDate and rt.RatingMethodID <> irt.RatingMethodID)
	)

	insert into  #PreviousExistingRates
	(
		RateID ,
		DestinationID ,
		CallTypeID ,
		RatingMethodID ,
		Rate ,
		BeginDate ,
		EndDate ,
		RateTypeID 
	)
	select tbl1.RateID , tbl1.DestinationID , tbl1.CallTypeID , tbl1.RatingMethodID,
	       tbl2.Rate , tbl1.BeginDate , tbl1.EndDate , tbl2.RatetypeID
	from UC_Reference.dbo.tb_Rate tbl1
	inner join UC_Reference.dbo.tb_RateDetail tbl2 on tbl1.RateID = tbl2.RateID
	inner join #IncomingOfferRates tbl3 on tbl1.DestinationID = tbl3.DestinationID and tbl1.CallTypeID = @CallTypeID
	where tbl1.RatePlanID = @RatePlanID
	and tbl3.EffectiveDate between tbl1.BeginDate and ISNULL(tbl1.EndDate , tbl3.EffectiveDate)
	
	--------------------
	-- Debugging Start
	--------------------

	select 'Previous Rate' , *
	from #PreviousExistingRates
	
	---------------------
	-- Debugging End
	---------------------

	--------------------------------------------------------------------
	-- Populate the Amount change and Prev BeginDate and Rate Increase
	-- or Decrease information for all the rates
	---------------------------------------------------------------------

	Update tbl1 
	set AmountChange = (tbl1.Rate - tbl2.Rate) , 
	    PrevRate = tbl2.Rate,
	    PrevBeginDate =   tbl2.BeginDate , 
        Flag = 
		   Case
				When (tbl1.Rate - tbl2.Rate) <> 0 then 64
				Else 0
		   End
	from #IncomingOfferRates tbl1
	inner join #PreviousExistingRates tbl2 on tbl1.DestinationID = tbl2.DestinationID
					and tbl1.RateTypeID = tbl2.RateTypeID

	--------------------
	-- Debugging Start
	--------------------

	select 'Incoming Rate After Check' , *
	from #IncomingOfferRates
	
	---------------------
	-- Debugging End
	---------------------

	-------------------------------------------------------
	-- Call the stored procedure to commit new rates and
	-- expire previous rates
	-------------------------------------------------------

	 Exec SP_BSCommitOfferRates @RatePlanID , @CallTypeID , @UserID

	---------------------------------------------------------------
	-- Delete the previously marked records for deleteion from the 
	-- rate detail and rate tables
	---------------------------------------------------------------

	delete tbl1
	from UC_Reference.dbo.tb_RateDetail tbl1
	inner join UC_Reference.dbo.tb_Rate tbl2 on tbl1.RateId = tbl2.RateID
	where tbl2.RatePlanID = @RatePlanID
	and tbl2.CalltypeID =  @CallTypeID
	and tbl2.Flag & 1 = 1

	delete from UC_Reference.dbo.tb_Rate 
	where RatePlanID = @RatePlanID
	and CalltypeID =  @CallTypeID
	and Flag & 1 = 1

	------------------------------------------------------
	-- Update the Upload Rate reference table with info
	-- from the temp table
	------------------------------------------------------

	update tbl1
	set tbl1.PrevRate = tbl2.PrevRate,
	    tbl1.PrevBeginDate = tbl2.PrevBeginDate,
		tbl1.Flag = tbl2.Flag
	from tb_RateAnalysisSummary tbl1
	inner join #IncomingOfferRates tbl2 on tbl1.RateAnalysisSummaryID = tbl2.UploadRateID

	Fetch Next From UploadReferenceRates_Cur
	Into @VarEffectiveDate

End

Close UploadReferenceRates_Cur
Deallocate UploadReferenceRates_Cur

----------------------------------------------------------------------
-- Drop all the temporary tables created for processing of the rates
----------------------------------------------------------------------
Drop table #IncomingOfferRates
Drop Table #PreviousExistingRates



Return 0
GO
