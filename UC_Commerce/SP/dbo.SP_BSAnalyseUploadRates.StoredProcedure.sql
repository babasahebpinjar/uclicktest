USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSAnalyseUploadRates]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSAnalyseUploadRates]
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


Declare @RateIncreasePeriod int,
        @RateDecreasePeriod int

select @RateIncreasePeriod = ISNULL(IncreaseNoticePeriod , 0) ,
       @RateDecreasePeriod = ISNULL(DecreaseNoticePeriod , 0)
from UC_Reference.dbo.tb_RatePlan
where RatePlanID = @RatePlanID
        

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

Declare UploadRates_Cur Cursor For
select Distinct EffectiveDate
from #TempUploadRate
order by EffectiveDate

Open UploadRates_Cur
Fetch Next From UploadRates_Cur
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
	select tbl1.UploadRateID , tbl1.UploadDestinationID , tbl2.DestinationID, tbl2.RatingMethodID,
	       tbl1.Rate, tbl1.RateTypeID , tbl1.EffectiveDate , 0
	from #TempUploadRate tbl1
	inner join #TempUploadDestination tbl2 on tbl1.UploadDestinationID = tbl2.UploadDEstinationID
	where tbl2.EffectiveDate = @VarEffectiveDate

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
		(rt.BeginDate = irt.EffectiveDate and rtd.RateTypeID = irt.RateTypeID and rt.RatingMethodID = irt.RatingMethodID and rtd.Rate <> irt.Rate)
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
	PrevBeginDate =   tbl2.BeginDate , 
    Flag = 
		   Case
				When (tbl1.Rate - tbl2.Rate) <> 0 then 64
				Else 0
		   End
	from #IncomingOfferRates tbl1
	inner join #PreviousExistingRates tbl2 on tbl1.DestinationID = tbl2.DestinationID
					and tbl1.RateTypeID = tbl2.RateTypeID

    -------------------------------------------------------
	-- Mark the entries whether they are rate increase or
	-- Decrease
	-------------------------------------------------------
	
	update #IncomingOfferRates
	set Flag = Flag|131072
	where AmountChange > 0
	and Flag & 64 = 64
	and datediff(dd , @OfferDate , EffectiveDate) < @RateIncreasePeriod

	update #IncomingOfferRates
	set Flag = flag|262144
	where AmountChange <  0
	and Flag & 64 = 64
	and datediff(dd , @OfferDate , EffectiveDate) < @RateDecreasePeriod

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
	set tbl1.AmountChange = tbl2.AmountChange,
	    tbl1.PrevBeginDate = tbl2.PrevBeginDate,
		tbl1.Flag = tbl2.Flag
	from tb_UploadRate tbl1
	inner join #IncomingOfferRates tbl2 on tbl1.UploadRateID = tbl2.UploadRateID
	where tbl1.OfferID = @OfferID

	Fetch Next From UploadRates_Cur
	Into @VarEffectiveDate

End

Close UploadRates_Cur
Deallocate UploadRates_Cur

-------------------------------------------------------------------------
-- Expire all the other destinations for the countries provided as part
-- of the Full Country or A-Z offer
-------------------------------------------------------------------------

Select @ExpireEffectiveDateAZFlag = ConfigValue
from UC_Admin.dbo.tb_Config
where Configname = 'ExpireEffectiveDateAZ'

if ( ( @ExpireEffectiveDateAZFlag is Null ) or ( @ExpireEffectiveDateAZFlag not in (1,2,3) ))
Begin

	set @ExpireEffectiveDateAZFlag = 3 -- Default Value

End


select tbl3.CountryID , tbl3.CountryCode
into #TempSharedCountryCode
from UC_Reference.dbo.tb_EntityGroup tbl1
inner join UC_Reference.dbo.tb_EntityGroupMember tbl2 on tbl1.EntityGroupID = tbl2.EntityGroupID
inner join UC_Reference.dbo.tb_Country tbl3 on tbl2.InstanceID = tbl3.CountryID
where tbl1.EntityGroupTypeID = -4 -- Country Grouping

Create table #TempCountryData ( CountryID int , EffectiveDate Date , MinDate Date, MaxDate Date)

----------------------------------------------------------------------------------
-- Logic for finding the effective date:
-- If the max and min effective dates for destinations of a country in the offer 
-- is the same then use the Effective date
-- In case there are multiple Effective dates:
-- 1 : Use the Max value between offer date and Min Effective date for the country
-- 2 : Use the Offer Date
-- 3 : Use the MAx Effective date for the country
----------------------------------------------------------------------------------

if (@OfferContent in ('FC' , 'AZ' )) 
Begin

		insert into #TempCountryData
		(CountryID , EffectiveDate , MinDate , MaxDate)
		Select cou.CountryID ,
		   Case

				When Max(dest.EffectiveDate) = Min(dest.EffectiveDate) then Min(dest.EffectiveDate)
				When Max(dest.EffectiveDate) <> Min(dest.EffectiveDate) then
					Case

						When @ExpireEffectiveDateAZFlag = 1 then
							Case
								When Min(dest.EffectiveDate) > convert(date , @OfferDate) then Min(dest.EffectiveDate)
								When Min(dest.EffectiveDate) < convert(date , @OfferDate) then convert(date , @OfferDate)
								When Min(dest.EffectiveDate) = convert(date , @OfferDate) then convert(date , @OfferDate)								
							End
						When @ExpireEffectiveDateAZFlag = 2 then convert(date , @OfferDate)
						When @ExpireEffectiveDateAZFlag = 3 then max(dest.EffectiveDate)
					
					End						
		   End,
		   min(dest.EffectiveDate),
		   max(dest.EffectiveDate)
         from ( select DestinationID ,  min(EffectiveDate) EffectiveDate from #TempUploadDestination group by DestinationID) dest
		 inner join UC_Reference.dbo.tb_Destination refdest on dest.DestinationID = refdest.DestinationID
		 inner join UC_Reference.dbo.tb_Country cou on refdest.CountryID = cou.countryID
		 Group by cou.CountryID


End

---------------------------------------------------------------------------------
-- Incase of Full Country we need to expire all the destinations which exist in 
-- the system, and not part of the offer or country grouping.
-- The effective date for expiring the destinations would depend on the value for
-- parameter ExpireEffectiveDateAZFlag
----------------------------------------------------------------------------------

if ( @OfferContent = 'FC' )
Begin

	----------------------------------------------------------------
	-- Remove all the Countries from the Country table, which are
	-- part of a country group. This is to ensure that records of
	-- destinations which belong to Countries of a country group
	-- are not expoired
	----------------------------------------------------------------

	delete from #TempCountryData
	where countryid in
	( select CountryId from #TempSharedCountryCode )

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
	left join ( select distinct DestinationID from #TempUploadDestination ) dest on refdest.DestinationID = dest.DestinationID
	Where rt.RatePlanID = @RatePlanID
	and rt.CallTypeID = @CalltypeID
	and refdest.numberplanID = @NumberPlanID
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
	left join ( select distinct DestinationID from #TempUploadDestination ) dest on refdest.DestinationID = dest.DestinationID
	Where rt.RatePlanID = @RatePlanID
	and rt.CallTypeID = @CalltypeID
	and refdest.numberplanID = @NumberPlanID
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
	left join ( select distinct DestinationID from #TempUploadDestination ) dest on refdest.DestinationID = dest.DestinationID
	Where rt.RatePlanID = @RatePlanID
	and rt.CallTypeID = @CalltypeID
	and refdest.numberplanID = @NumberPlanID
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


if (@OfferContent = 'AZ' )
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
	left join ( select distinct DestinationID from #TempUploadDestination ) dest on refdest.DestinationID = dest.DestinationID
	Where rt.RatePlanID = @RatePlanID
	and rt.CallTypeID = @CalltypeID
	and refdest.numberplanID = @NumberPlanID
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
	left join ( select distinct DestinationID from #TempUploadDestination ) dest on refdest.DestinationID = dest.DestinationID
	Where rt.RatePlanID = @RatePlanID
	and rt.CallTypeID = @CalltypeID
	and refdest.numberplanID = @NumberPlanID
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
	left join ( select distinct DestinationID from #TempUploadDestination ) dest on refdest.DestinationID = dest.DestinationID
	Where rt.RatePlanID = @RatePlanID
	and rt.CallTypeID = @CalltypeID
	and refdest.numberplanID = @NumberPlanID
	and 
	(
		rt.EndDate is NULL
		or rt.EndDate >= cou.EffectiveDate
	)
	and dest.DestinationID is NULL


	Update rt
	set rt.EndDate = dateAdd(dd , -1 , convert(date , @OfferDate) ) ,
		rt.ModifiedDate = getdate(),
	 	rt.ModifiedByID = @UserID
	from UC_Reference.dbo.tb_Rate rt
	inner join UC_Reference.dbo.tb_Destination refdest on rt.destinationID = refdest.DestinationID
	Where rt.RatePlanID = @RatePlanID
	and rt.CallTypeID = @CalltypeID
	and refdest.numberplanID = @NumberPlanID
	and 
	(
		rt.EndDate is NULL
		or rt.EndDate >= convert(date , @OfferDate) 
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
Drop table #TempSharedCountryCode
Drop table #TempCountryData


Return 0
GO
