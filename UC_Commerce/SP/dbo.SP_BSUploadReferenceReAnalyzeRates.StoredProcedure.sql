USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSUploadReferenceReAnalyzeRates]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSUploadReferenceReAnalyzeRates]
(
	@NumberPlanAnalysisID int,
	@UserID int
)
As

Declare @SourceID int,
		@AnalysisStartDate DateTime,
		@AnalysisType varchar(50),
		@NumberPlanID int,
		@RatePlanID int,
		@CalltypeID int,
		@ExpireEffectiveDateAZFlag int

------------------------------------------------
-- Get essential attributes for the offer
------------------------------------------------

select @SourceID = SourceID,
       @AnalysisStartDate = AnalysisStartDate,
	   @AnalysisType = AnalysisType
from tb_NumberPlanAnalysis
where NumberPlanAnalysisID = @NumberPlanAnalysisID


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
	select tbl1.RateReAnalysisSummaryID , tbl1.RateReAnalysisID , tbl2.RefDestinationID, tbl2.RatingMethodID,
	       tbl1.AnalyzedRate, tbl1.RateTypeID , tbl2.AnalysisDate , 0
	from #TempUploadRate tbl1
	inner join #TempUploadDestination tbl2 on tbl1.RateReAnalysisID = tbl2.RateReAnalysisID
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
	from tb_RateReAnalysisSummary tbl1
	inner join #IncomingOfferRates tbl2 on tbl1.RateReAnalysisSummaryID = tbl2.UploadRateID

	Fetch Next From UploadReferenceRates_Cur
	Into @VarEffectiveDate

End

Close UploadReferenceRates_Cur
Deallocate UploadReferenceRates_Cur

-------------------------------------------------------------------------
-- Expire all the other destinations for the countries provided as part
-- of the Full Country or A-Z offer
-------------------------------------------------------------------------

Create table #TempCountryData ( CountryID int , EffectiveDate Date , MinDate Date, MaxDate Date)

insert into #TempCountryData
(CountryID , EffectiveDate , MinDate , MaxDate)
Select cou.CountryID , max(dest.EffectiveDate),
	   min(dest.EffectiveDate),
	   max(dest.EffectiveDate)
from ( select RefDestinationID DestinationID ,  min(AnalysisDate) EffectiveDate from #TempUploadDestination group by RefDestinationID) dest
inner join UC_Reference.dbo.tb_Destination refdest on dest.DestinationID = refdest.DestinationID
inner join UC_Reference.dbo.tb_Country cou on refdest.CountryID = cou.countryID
Group by cou.CountryID

---------------------------------------------------------------------------------
-- Incase of Full Country we need to expire all the destinations which exist in 
-- the system, and not part of destinations for the country ReAnalysis List 
---------------------------------------------------------------------------------

if ( @AnalysisType = 'FC' )
Begin

   -------------------------------------------------------------------------------------
   -- Before updating the end date for all the records, check if there are any records 
   -- where the new populated End Date is lesser than the Begin date of the record.
   -- Incase such records are encountered, we need to delete them from rates and ratedetail
   -----------------------------------------------------------------------------------------

    delete rtd
	from UC_Reference.dbo.tb_RateDetail rtd
	inner join UC_Reference.dbo.tb_Rate rt on rt.rateid = rtd.rateid
	inner join UC_Reference.dbo.tb_Destination refdest on rt.destinationID = refdest.DestinationID
	inner join #TempCountryData cou on refdest.CountryID = cou.CountryID
	left join ( select distinct RefDestinationID DestinationID from #TempUploadDestination ) dest on refdest.DestinationID = dest.DestinationID
	Where rt.RatePlanID = @RatePlanID
	and rt.CallTypeID = @CalltypeID
	and refdest.numberplanID = -1 -- Routing Number Plan
	and 
	(
		rt.EndDate is NULL
		or rt.EndDate >= cou.EffectiveDate
	)
	and dest.DestinationID is NULL
	and rt.BeginDate > dateAdd(dd , -1 , cou.EffectiveDate )

    delete rt
	from  UC_Reference.dbo.tb_Rate rt 
	inner join UC_Reference.dbo.tb_Destination refdest on rt.destinationID = refdest.DestinationID
	inner join #TempCountryData cou on refdest.CountryID = cou.CountryID
	left join ( select distinct RefDestinationID DestinationID from #TempUploadDestination ) dest on refdest.DestinationID = dest.DestinationID
	Where rt.RatePlanID = @RatePlanID
	and rt.CallTypeID = @CalltypeID
	and refdest.numberplanID = -1 -- Routing Number Plan
	and 
	(
		rt.EndDate is NULL
		or rt.EndDate >= cou.EffectiveDate
	)
	and dest.DestinationID is NULL
	and rt.BeginDate > dateAdd(dd , -1 , cou.EffectiveDate )

	Update rt
	set rt.EndDate = dateAdd(dd , -1 , cou.EffectiveDate ),
		rt.ModifiedDate = getdate(),
	 	rt.ModifiedByID = @UserID
	from UC_Reference.dbo.tb_Rate rt
	inner join UC_Reference.dbo.tb_Destination refdest on rt.destinationID = refdest.DestinationID
	inner join #TempCountryData cou on refdest.CountryID = cou.CountryID
	left join ( select distinct RefDestinationID DestinationID from #TempUploadDestination ) dest on refdest.DestinationID = dest.DestinationID
	Where rt.RatePlanID = @RatePlanID
	and rt.CallTypeID = @CalltypeID
	and refdest.numberplanID = -1 -- Routing Number Plan
	and 
	(
		rt.EndDate is NULL
		or rt.EndDate >= cou.EffectiveDate
	)
	and dest.DestinationID is NULL


End

--------------------------------------------------------------------
-- In case of an AZ offer, we need to first expire rates
-- for all destinations which belong to countries in the offer
-- but have not been provided. Then End Date would be determined
-- by the effective date of the country

-- Secondly wee need to expire all the rates for destinations which
-- belong to countries which have not been offered.These will have
-- the End date as the offer date - 1
---------------------------------------------------------------------


if (@AnalysisType = 'AZ' )
Begin

   -------------------------------------------------------------------------------------
   -- Before updating the end date for all the records, check if there are any records 
   -- where the new populated End Date is lesser than the Begin date of the record.
   -- Incase such records are encountered, we need to delete them from rates and ratedetail
   -----------------------------------------------------------------------------------------

    delete rtd
	from UC_Reference.dbo.tb_RateDetail rtd
	inner join UC_Reference.dbo.tb_Rate rt on rt.rateid = rtd.rateid
	inner join UC_Reference.dbo.tb_Destination refdest on rt.destinationID = refdest.DestinationID
	inner join #TempCountryData cou on refdest.CountryID = cou.CountryID
	left join ( select distinct RefDestinationID DestinationID from #TempUploadDestination ) dest on refdest.DestinationID = dest.DestinationID
	Where rt.RatePlanID = @RatePlanID
	and rt.CallTypeID = @CalltypeID
	and refdest.numberplanID = -1 -- Routing Number Plan
	and 
	(
		rt.EndDate is NULL
		or rt.EndDate >= cou.EffectiveDate
	)
	and dest.DestinationID is NULL
	and rt.BeginDate > dateAdd(dd , -1 , cou.EffectiveDate )

    delete rt
	from  UC_Reference.dbo.tb_Rate rt 
	inner join UC_Reference.dbo.tb_Destination refdest on rt.destinationID = refdest.DestinationID
	inner join #TempCountryData cou on refdest.CountryID = cou.CountryID
	left join ( select distinct RefDestinationID DestinationID from #TempUploadDestination ) dest on refdest.DestinationID = dest.DestinationID
	Where rt.RatePlanID = @RatePlanID
	and rt.CallTypeID = @CalltypeID
	and refdest.numberplanID = -1 -- Routing Number Plan
	and 
	(
		rt.EndDate is NULL
		or rt.EndDate >= cou.EffectiveDate
	)
	and dest.DestinationID is NULL
	and rt.BeginDate > dateAdd(dd , -1 , cou.EffectiveDate )


	Update rt
	set rt.EndDate = dateAdd(dd , -1 , cou.EffectiveDate ),
	    rt.ModifiedDate = getdate(),
	 	rt.ModifiedByID = @UserID
	from UC_Reference.dbo.tb_Rate rt
	inner join UC_Reference.dbo.tb_Destination refdest on rt.destinationID = refdest.DestinationID
	inner join #TempCountryData cou on refdest.CountryID = cou.CountryID
	left join ( select distinct RefDestinationID DestinationID from #TempUploadDestination ) dest on refdest.DestinationID = dest.DestinationID
	Where rt.RatePlanID = @RatePlanID
	and rt.CallTypeID = @CalltypeID
	and refdest.numberplanID = -1 -- Routing Number Plan
	and 
	(
		rt.EndDate is NULL
		or rt.EndDate >= cou.EffectiveDate
	)
	and dest.DestinationID is NULL


	Update rt
	set rt.EndDate = dateAdd(dd , -1 , convert(date , @AnalysisStartDate) ) ,
		rt.ModifiedDate = getdate(),
	 	rt.ModifiedByID = @UserID
	from UC_Reference.dbo.tb_Rate rt
	inner join UC_Reference.dbo.tb_Destination refdest on rt.destinationID = refdest.DestinationID
	Where rt.RatePlanID = @RatePlanID
	and rt.CallTypeID = @CalltypeID
	and refdest.numberplanID = -1 -- Routing Number Plan
	and 
	(
		rt.EndDate is NULL
		or rt.EndDate >= convert(date , @AnalysisStartDate) 
	)
	and refdest.countryid not in
	(
		select countryid from #TempCountryData
	)


End

----------------------------------------------------------------------
-- Drop all the temporary tables created for processing of the rates
----------------------------------------------------------------------
Drop table #IncomingOfferRates
Drop Table #PreviousExistingRates
Drop table #TempCountryData


Return 0
GO
