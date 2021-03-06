USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSCommitOfferRates]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSCommitOfferRates]
(
	@RatePlanID int,
	@CallTypeID int,
	@UserID int
)
As

-----------------------------------------------------
-- Create temporary tables to hold the new rates
-----------------------------------------------------

Create table #NewRate
(
	UploadUniqueID int,
	RatePlanID int,
	DestinationID int,
	CallTypeID int,
	RatingMethodID int,
	BeginDate Date,
	EndDate Date
)

Create table #NewRateDetail
(
	Rate decimal(19,6),
	UploadUniqueID int,
	RateTypeID int
)


---------------------------------------------------------------------------------
-- ******************** RATE RECORDS FOR SINGLE RATE TYPE ***********************
---------------------------------------------------------------------------------

---------------------------------------------------
--  Select the list of destinatiations from the
-- upload offer, which have only one rate type
---------------------------------------------------

select DestinationID , EffectiveDate , RatingMethodID 
into #TempDestinationWithSingleRateType
from
(
	Select DestinationID, EffectiveDate , RatingMethodID , Count(*) as TotalRecords
	from #IncomingOfferRates
	group by DestinationID , EffectiveDate , RatingMethodID
	having count(3) = 1 -- Only one rate type
) as tbl1


--------------------------------------------------------------------
-- For all those destinations which are having new rates, create
-- entries for Rate and Rate Detail
--------------------------------------------------------------------

insert into #NewRate
(
	UploadUniqueID ,
	RatePlanID ,
	DestinationID ,
	CallTypeID ,
	RatingMethodID ,
	BeginDate ,
	EndDate 
)
select tbl1.UploadDestinationID , @RatePlanID , tbl1.DestinationID , @CallTypeID,
       tbl1.RatingMethodID , tbl1.EffectiveDate , NULL
from #IncomingOfferRates tbl1
inner join #TempDestinationWithSingleRateType tbl2 on 
            tbl1.DestinationID = tbl2.DestinationID
			and
			tbl1.EffectiveDate = tbl2.EffectiveDate
			and
			tbl1.RatingMethodID = tbl2.RatingMethodID
where isnull(tbl1.AmountChange, 0) = 0
and tbl1.PrevBeginDate is NULL
and tbl1.Flag = 0


insert into #NewRateDetail
(
	UploadUniqueID ,
	RateTypeID ,
	Rate 
)
select tbl1.UploadDestinationID ,tbl1.RateTypeID , tbl1.Rate
from #IncomingOfferRates tbl1
inner join #TempDestinationWithSingleRateType tbl2 on 
            tbl1.DestinationID = tbl2.DestinationID
			and
			tbl1.EffectiveDate = tbl2.EffectiveDate
			and
			tbl1.RatingMethodID = tbl2.RatingMethodID
where isnull(tbl1.AmountChange, 0) = 0
and tbl1.PrevBeginDate is NULL
and tbl1.Flag = 0


---------------------------------------------------------------
-- Expire all those previous rates where the RATE TYPE does
-- not match with the rate type of the incoming offer record
-- resulting in the incoming record being treated as new
---------------------------------------------------------------

update prt 
set prt.EndDate = irt.EffectiveDate -1
from
(
	select tbl1.*
	from #IncomingOfferRates tbl1
	inner join #TempDestinationWithSingleRateType tbl2 on 
				tbl1.DestinationID = tbl2.DestinationID
				and
				tbl1.EffectiveDate = tbl2.EffectiveDate
				and
				tbl1.RatingMethodID = tbl2.RatingMethodID
	where isnull(tbl1.AmountChange, 0) = 0
	and tbl1.PrevBeginDate is NULL
	and tbl1.Flag = 0 -- New Record
) irt
inner join #PreviousExistingRates prt on irt.destinationid = prt.DestinationID
                      and irt.RateTypeID <> prt.RatetypeID

-------------------------------------------------------------
-- For all destinations which have Rate Change, we need to
-- expire the old rates and create entries for new rate
-------------------------------------------------------------

update prt 
set prt.EndDate = irt.EffectiveDate -1
from
(
	select tbl1.*
	from #IncomingOfferRates tbl1
	inner join #TempDestinationWithSingleRateType tbl2 on 
				tbl1.DestinationID = tbl2.DestinationID
				and
				tbl1.EffectiveDate = tbl2.EffectiveDate
				and
				tbl1.RatingMethodID = tbl2.RatingMethodID
	where isnull(tbl1.AmountChange, 0) <> 0
	and tbl1.PrevBeginDate is not NULL
	and tbl1.Flag & 64 = 64 -- Change in Amount
) irt
inner join #PreviousExistingRates prt on irt.destinationid = prt.DestinationID
                      and irt.RateTypeID = prt.RatetypeID


insert into #NewRate
(
	UploadUniqueID ,
	RatePlanID ,
	DestinationID ,
	CallTypeID ,
	RatingMethodID ,
	BeginDate ,
	EndDate 
)
select tbl1.UploadDestinationID , @RatePlanID , tbl1.DestinationID , @CallTypeID,
       tbl1.RatingMethodID , tbl1.EffectiveDate , NULL
from #IncomingOfferRates tbl1
inner join #TempDestinationWithSingleRateType tbl2 on 
            tbl1.DestinationID = tbl2.DestinationID
			and
			tbl1.EffectiveDate = tbl2.EffectiveDate
			and
			tbl1.RatingMethodID = tbl2.RatingMethodID
where isnull(tbl1.AmountChange, 0) <> 0
and tbl1.PrevBeginDate is not NULL
and tbl1.Flag & 64 = 64


insert into #NewRateDetail
(
	UploadUniqueID ,
	RateTypeID ,
	Rate 
)
select tbl1.UploadDestinationID ,tbl1.RateTypeID , tbl1.Rate
from #IncomingOfferRates tbl1
inner join #TempDestinationWithSingleRateType tbl2 on 
            tbl1.DestinationID = tbl2.DestinationID
			and
			tbl1.EffectiveDate = tbl2.EffectiveDate
			and
			tbl1.RatingMethodID = tbl2.RatingMethodID
where isnull(tbl1.AmountChange, 0) <> 0
and tbl1.PrevBeginDate is not NULL
and tbl1.Flag & 64 = 64


--------------------------------------------------------------------------
-- For all the records where the previous rate is same as the new rate
-- we need to check if the rating method is different or not.
-- in case the rating mwethod is different, we need to expire the
-- previous record
--------------------------------------------------------------------------

update prt 
set prt.EndDate = 
                  Case
				       When irt.RatingMethodID <> prt.RatingMEthodID then irt.EffectiveDate -1
					   Else NULL
				  End
from
(
	select tbl1.*
	from #IncomingOfferRates tbl1
	inner join #TempDestinationWithSingleRateType tbl2 on 
				tbl1.DestinationID = tbl2.DestinationID
				and
				tbl1.EffectiveDate = tbl2.EffectiveDate
				and
				tbl1.RatingMethodID = tbl2.RatingMethodID
	where isnull(tbl1.AmountChange, 0) = 0
	and tbl1.PrevBeginDate is not NULL
	and tbl1.Flag = 0 -- No Change in Amount
) irt
inner join #PreviousExistingRates prt on irt.destinationid = prt.DestinationID
                      and irt.RateTypeID = prt.RatetypeID


insert into #NewRate
(
	UploadUniqueID ,
	RatePlanID ,
	DestinationID ,
	CallTypeID ,
	RatingMethodID ,
	BeginDate ,
	EndDate 
)
select tbl1.UploadDestinationID , @RatePlanID , tbl1.DestinationID , @CallTypeID,
       tbl1.RatingMethodID , tbl1.EffectiveDate , NULL
from #IncomingOfferRates tbl1
inner join #TempDestinationWithSingleRateType tbl2 on 
            tbl1.DestinationID = tbl2.DestinationID
			and
			tbl1.EffectiveDate = tbl2.EffectiveDate
			and
			tbl1.RatingMethodID = tbl2.RatingMethodID
inner join #PreviousExistingRates tbl3 on tbl1.destinationid = tbl3.DestinationID
                      and tbl1.RateTypeID = tbl3.RatetypeID
where isnull(tbl1.AmountChange, 0) = 0
and tbl1.PrevBeginDate is not NULL
and tbl1.Flag = 0
and tbl1.RatingMethodID <> tbl3.RatingMethodID


insert into #NewRateDetail
(
	UploadUniqueID ,
	RateTypeID ,
	Rate 
)
select tbl1.UploadDestinationID ,tbl1.RateTypeID , tbl1.Rate
from #IncomingOfferRates tbl1
inner join #TempDestinationWithSingleRateType tbl2 on 
            tbl1.DestinationID = tbl2.DestinationID
			and
			tbl1.EffectiveDate = tbl2.EffectiveDate
			and
			tbl1.RatingMethodID = tbl2.RatingMethodID
inner join #PreviousExistingRates tbl3 on tbl1.destinationid = tbl3.DestinationID
                      and tbl1.RateTypeID = tbl3.RatetypeID
where isnull(tbl1.AmountChange, 0) = 0
and tbl1.PrevBeginDate is not NULL
and tbl1.Flag = 0
and tbl1.RatingMethodID <> tbl3.RatingMethodID

-----------------------------------------------------------------------------------
-- ******************** RATE RECORDS FOR MULTIPLE RATE TYPE ***********************
-----------------------------------------------------------------------------------

---------------------------------------------------
--  Select the list of destinatiations from the
-- upload offer, which have only one rate type
---------------------------------------------------

select DestinationID , EffectiveDate , RatingMethodID 
into #TempDestinationWithMultipleRateType
from
(
	Select DestinationID , EffectiveDate , RatingMethodID , Count(*) as TotalRecords
	from #IncomingOfferRates
	group by DestinationID , EffectiveDate , RatingMethodID
	having count(3)  > 1 -- Multiple rate type
) as tbl1


------------------------------------------------------------------
-- From the table of Destinations with Multiple Rate Type create
-- table of Amount Change or New Rate Scenario
------------------------------------------------------------------


select distinct tbl1.DestinationID , tbl1.EffectiveDate , tbl1.RatingMethodID
into #TempDestinationWithMultipleRateTypeMultipleScenario
from #IncomingOfferRates tbl1
inner join #TempDestinationWithMultipleRateType tbl2 on
            tbl1.DestinationID = tbl2.DestinationID
			and
			tbl1.EffectiveDate = tbl2.EffectiveDate
			and
			tbl1.RatingMethodID = tbl2.RatingMethodID
where 
(
	isnull(tbl1.AmountChange, 0) = 0
	and tbl1.PrevBeginDate is NULL
	and tbl1.Flag = 0
) -- New Rate
or
(
	isnull(tbl1.AmountChange, 0) <> 0
	and tbl1.PrevBeginDate is not NULL
	and tbl1.Flag & 64 = 64 	
) -- -- Change in Amount


--------------------------------------------------------------
-- For all the destinations having multiple rate types and
-- one or more scenario for NEw Rate or Rate Change, we
-- need to expire the old rates
--------------------------------------------------------------

update prt 
set prt.EndDate = irt.EffectiveDate -1
from #TempDestinationWithMultipleRateTypeMultipleScenario irt
inner join #PreviousExistingRates prt on irt.destinationid = prt.DestinationID


insert into #NewRate
(
	UploadUniqueID ,
	RatePlanID ,
	DestinationID ,
	CallTypeID ,
	RatingMethodID ,
	BeginDate ,
	EndDate 
)
select Distinct tbl1.UploadDestinationID , @RatePlanID , tbl1.DestinationID , @CallTypeID,
       tbl1.RatingMethodID , tbl1.EffectiveDate , NULL
from #IncomingOfferRates tbl1
inner join #TempDestinationWithMultipleRateTypeMultipleScenario tbl2 on 
            tbl1.DestinationID = tbl2.DestinationID
			and
			tbl1.EffectiveDate = tbl2.EffectiveDate
			and
			tbl1.RatingMethodID = tbl2.RatingMethodID


insert into #NewRateDetail
(
	UploadUniqueID ,
	RateTypeID ,
	Rate 
)
select tbl1.UploadDestinationID ,tbl1.RateTypeID , tbl1.Rate
from #IncomingOfferRates tbl1
inner join #TempDestinationWithMultipleRateTypeMultipleScenario tbl2 on 
            tbl1.DestinationID = tbl2.DestinationID
			and
			tbl1.EffectiveDate = tbl2.EffectiveDate
			and
			tbl1.RatingMethodID = tbl2.RatingMethodID



-------------------------------------------------------------------
-- Now process all the destinations having multiple rate types but
-- do not have rate change or new rate scenario. These should be
-- all the destinations which have no rate change, but could have a
-- rating method change which would require new records
-------------------------------------------------------------------

update prt 
set prt.EndDate = 
				Case
					When irt.RatingMethodID <> prt.RatingMethodID then irt.EffectiveDate -1
					Else NULL
				End
from #TempDestinationWithMultipleRateType irt
inner join #PreviousExistingRates prt on irt.destinationid = prt.DestinationID
where irt.DestinationID not in
(
	Select Distinct DestinationID
	from #TempDestinationWithMultipleRateTypeMultipleScenario
)


insert into #NewRate
(
	UploadUniqueID ,
	RatePlanID ,
	DestinationID ,
	CallTypeID ,
	RatingMethodID ,
	BeginDate ,
	EndDate 
)
select Distinct tbl1.UploadDestinationID , @RatePlanID , tbl1.DestinationID , @CallTypeID,
       tbl1.RatingMethodID , tbl1.EffectiveDate , NULL
from #IncomingOfferRates tbl1
inner join #TempDestinationWithMultipleRateType tbl2 on 
            tbl1.DestinationID = tbl2.DestinationID
			and
			tbl1.EffectiveDate = tbl2.EffectiveDate
			and
			tbl1.RatingMethodID = tbl2.RatingMethodID
inner join #PreviousExistingRates tbl3 on tbl2.destinationid = tbl3.DestinationID
where tbl2.RatingMethodID <> tbl3.RatingMethodID
and tbl2.DestinationID not in
(
	Select Distinct DestinationID
	from #TempDestinationWithMultipleRateTypeMultipleScenario
)


insert into #NewRateDetail
(
	UploadUniqueID ,
	RateTypeID ,
	Rate 
)
select tbl1.UploadDestinationID ,tbl1.RateTypeID , tbl1.Rate
from #IncomingOfferRates tbl1
inner join #TempDestinationWithMultipleRateType tbl2 on 
            tbl1.DestinationID = tbl2.DestinationID
			and
			tbl1.EffectiveDate = tbl2.EffectiveDate
			and
			tbl1.RatingMethodID = tbl2.RatingMethodID
inner join #PreviousExistingRates tbl3 on tbl2.destinationid = tbl3.DestinationID
where tbl2.RatingMethodID <> tbl3.RatingMethodID
and tbl2.DestinationID not in
(
	Select Distinct DestinationID
	from #TempDestinationWithMultipleRateTypeMultipleScenario
)



---------------------------------------------------------------------------
-- Update the details of new and previous rates into actual reference tables
---------------------------------------------------------------------------

update rt
set	rt.EndDate = prt.EndDate,
	rt.ModifiedByID = @UserID,
	rt.ModifiedDate = getdate()
from UC_Reference.dbo.tb_Rate rt
inner join #PreviousExistingRates prt on rt.RateID = prt.RateID

insert into UC_Reference.dbo.tb_Rate
(
	RatePlanID,
	DestinationID,
	CallTypeID,
	RatingMethodID,
	BeginDate,
	EndDate,
	ModifiedDate,
	ModifiedByID,
	Flag
)
select RatePlanID , DestinationID , CallTypeID , RatingMethodID,
       BeginDate , EndDate , Getdate() ,  @UserID , 0
from #NewRate


insert into UC_Reference.dbo.tb_RateDetail
(
	Rate,
	RateID,
	RateTypeID,
	ModifiedDate,
	ModifiedByID,
	Flag
)       
Select nrtd.Rate , rt.RateID , nrtd.RateTypeID , getdate() , @UserID , 0
from #NewRateDetail nrtd
inner join #NewRate nrt on nrtd.UploadUniqueID = nrt.UploadUniqueID
inner join UC_Reference.dbo.tb_Rate rt on 
              nrt.RatePlanID = rt.RatePlanID
			  and
			  nrt.DestinationID = rt.DestinationID
			  and
			  nrt.RatingMethodID = rt.RatingMethodID
			  and
			  nrt.CallTypeID = rt.CallTypeID
			  and
			  nrt.BeginDate = rt.BeginDate
Where rt.RatePlanID = @RatePlanID
and rt.CallTypeID = @CallTypeID	
and rt.Flag & 1 <> 1


Select 'Debug .... New Rate to Insert' , *
from #NewRate	        
 
-----------------------------------------------------------
-- Drop all the temporary table post processing of data
-----------------------------------------------------------

Drop table #TempDestinationWithSingleRateType
Drop table #TempDestinationWithMultipleRateType
Drop table #TempDestinationWithMultipleRateTypeMultipleScenario
Drop table #NewRate
Drop table #NewRateDetail
GO
