USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_RPTRoutingRateIncreaseReportByEmail]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_RPTRoutingRateIncreaseReportByEmail]
(
	@SelectDate date
)
As

--Declare @SelectDate date = '2019-01-31'


if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAllFutureRates') )
		Drop table #TempAllFutureRates

select rp.rateplan, rp.rateplanID ,dest.DestinationID , dest.destination , 
       cp.CalltypeID , cp.CallType,
       rt.begindate , rt.EndDate , rd.Rate
into #TempAllFutureRates
from ReferenceServer.UC_Reference.dbo.tb_Rateplan rp
inner join ReferenceServer.UC_Reference.dbo.tb_rate rt on rp.rateplanid = rt.rateplanid
inner join ReferenceServer.UC_Reference.dbo.tb_destination dest on rt.Destinationid = dest.Destinationid
inner join ReferenceServer.UC_Reference.dbo.tb_ratedetail rd on rt.rateid = rd.rateid
inner join ReferenceServer.UC_Reference.dbo.tb_Calltype cp on rt.CallTypeID = cp.CalltypeID
where rp.directionid = 2
and rp.ProductCataLogID = -4
and dest.numberplanid = -1 
and rt.begindate >= @SelectDate

-- Select all the minimum Begin Dates which are nearest in future

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAllNearFutureDateRec') )
		Drop table #TempAllNearFutureDateRec

select rateplan, rateplanid ,DestinationID , destination , 
       CalltypeId , Calltype,
       min(BeginDate) as MinBeginDate
into #TempAllNearFutureDateRec
from #TempAllFutureRates
group by rateplan, rateplanid , DestinationID , destination, CalltypeId , Calltype


--select all the records in the future which are nearest and get their details

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAllNearFutureRec') )
		Drop table #TempAllNearFutureRec

select tbl1.RatePlanID , tbl1.RatePlan,
       tbl1.DestinationID , tbl1.Destination,
	   tbl1.CalltypeID , tbl1.Calltype,
	   tbl1.BeginDate , tbl1.EndDate , tbl1.Rate
into #TempAllNearFutureRec
from #TempAllFutureRates tbl1
inner join #TempAllNearFutureDateRec tbl2 on
         tbl1.rateplanid = tbl2.rateplanid
		 and
		 tbl1.DestinationID = tbl2.DestinationID
		 and
		 tbl1.CalltypeId = tbl2.CalltypeID
		 and
		 tbl1.BeginDate = tbl2.MinBeginDate


--For all the future records check if there are any previous records existing
--whose rates can be used for comparison to establish if routing rate has
--increased or not

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAllPreviousRates') )
		Drop table #TempAllPreviousRates

select rp.rateplan, rp.rateplanID ,dest.DestinationID , dest.destination , 
       cp.CalltypeID , cp.Calltype,
       rt.begindate , rt.EndDate , rd.Rate
into #TempAllPreviousRates
from ReferenceServer.UC_Reference.dbo.tb_Rateplan rp
inner join ReferenceServer.UC_Reference.dbo.tb_rate rt on rp.rateplanid = rt.rateplanid
inner join ReferenceServer.UC_Reference.dbo.tb_destination dest on rt.Destinationid = dest.Destinationid
inner join ReferenceServer.UC_Reference.dbo.tb_ratedetail rd on rt.rateid = rd.rateid
inner join ReferenceServer.UC_Reference.dbo.tb_Calltype cp on rt.CalltypeId = cp.CalltypeID
where rp.directionid = 2
and rp.ProductCataLogID = -4
and dest.numberplanid = -1 
and rt.begindate < @SelectDate

--Get dates for records which are the most latest in the past. These will be used
--for comparison against the future records to establish if rate has increased or not

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAllLatestPreviousDateRec') )
		Drop table #TempAllLatestPreviousDateRec

select rateplan, rateplanid ,DestinationID , destination , 
       CalltypeID , Calltype,
       max(BeginDate) as MaxBeginDate
into #TempAllLatestPreviousDateRec
from #TempAllPreviousRates
group by rateplan, rateplanid , DestinationID , destination , CalltypeId , CallType

--Get all the latest previous records for comparison against the future records

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAllPreviousRec') )
		Drop table #TempAllPreviousRec

select tbl1.RatePlanID , tbl1.RatePlan,
       tbl1.DestinationID , tbl1.Destination,
	   tbl1.CalltypeID , tbl1.Calltype,
	   tbl1.BeginDate , tbl1.EndDate , tbl1.Rate
into #TempAllPreviousRec
from #TempAllPreviousRates tbl1
inner join #TempAllLatestPreviousDateRec tbl2 on
         tbl1.rateplanid = tbl2.rateplanid
		 and
		 tbl1.DestinationID = tbl2.DestinationID
		 and
		 tbl1.CalltypeId = tbl2.CalltypeID
		 and
		 tbl1.BeginDate = tbl2.MaxBeginDate


-- Build the master table for Future rates and previous rates

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAllRateIncreaseRec') )
		Drop table #TempAllRateIncreaseRec

select tbl1.RatePlanID , tbl1.RatePlan , 
       tbl1.DestinationID , tbl1.Destination,
       tbl1.CalltypeID , tbl1.Calltype,
       convert(date,tbl1.BeginDate) as FutureRateBeginDate , convert(date ,tbl1.EndDate) as FutureRateEndDate,
	   convert(date,tbl2.BeginDate) as PreviousRateBeginDate , convert(date,tbl2.EndDate) as PreviousRateEndDate,
	   tbl1.Rate as FutureRate , tbl2.Rate as PreviousRate,
	   convert(Decimal(19,2) ,((tbl1.Rate - tbl2.Rate) * 100)/tbl2.Rate) PercentRateIncrease
into #TempAllRateIncreaseRec
from #TempAllNearFutureRec tbl1
inner join #TempAllPreviousRec tbl2 on
        tbl1.rateplanid = tbl2.Rateplanid
		and
		tbl1.DestinationId = tbl2.DestinationID
		and
		tbl1.CalltypeID = tbl2.CalltypeID
where tbl2.Rate <> 99.99 -- Exclude all the records where previous rate was due to Dialled Digit gap
and (tbl1.Rate - tbl2.Rate) > 0 -- Only consider records where there is a rate increase

--select * from #TempAllRateIncreaseRec

-- For all the records which have a rate increase, check if there was any traffic in the last 7 days
-- This will help establish if traffic was being routed to the particular partner for this destination
-- or not

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempTrafficProfile') )
		Drop table #TempTrafficProfile

select tbl1.DestinationID , tbl1.Destination,
       tbl1.RatePlanId , tbl1.RatePlan ,
	   tbl1.CallTypeID , tbl1.CallType	,
      isnull(convert(Decimal(19,2) ,sum(convert(float ,CallDuration))/60.0),0) as TrafficMinutes
into #TempTrafficProfile
from #TempAllRateIncreaseRec tbl1
left join 
(
    select * from tb_DailyINUnionOutFinancial
	where DirectionID = 2 -- Outbound
	and CallDate between DateAdd(dd , -7 , @SelectDate) and @SelectDate

) tbl2 on
        tbl1.RatePlanID = tbl2.RatePlanID
		and
		tbl1.DestinationID = tbl2.RoutingDestinationID
		and
		tbl1.CalltypeID = tbl2.CalltypeID
group by tbl1.DestinationID , tbl1.Destination,
         tbl1.RatePlanId , tbl1.RatePlan ,
	     tbl1.CallTypeID , tbl1.CallType


-- Prepare the final master table with Rate and Traffic Profile information

select tbl1.RatePlanID , tbl1.RatePlan,
	   tbl1.DestinationID , tbl1.Destination,
	   tbl1.RatePlanID , tbl1.RatePlan,
	   tbl1.FutureRateBeginDate , tbl1.FutureRateEndDate,
	   tbl1.PreviousRateBeginDate , tbl1.PreviousRateEndDate,
	   tbl1.FutureRate , tbl1.PreviousRate, tbl1.PercentRateIncrease,
	   tbl2.TrafficMinutes
from #TempAllRateIncreaseRec tbl1
inner join #TempTrafficProfile tbl2 on
          tbl1.DestinationID = tbl2.DestinationID
		  and
		  tbl1.CalltypeID = tbl2.CalltypeID
		  and
		  tbl1.RatePlanID = tbl2.RateplanID

ENDPROCESSS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAllFutureRates') )
		Drop table #TempAllFutureRates

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAllNearFutureDateRec') )
		Drop table #TempAllNearFutureDateRec

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAllNearFutureRec') )
		Drop table #TempAllNearFutureRec

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAllPreviousRates') )
		Drop table #TempAllPreviousRates

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAllLatestPreviousDateRec') )
		Drop table #TempAllLatestPreviousDateRec

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAllPreviousRec') )
		Drop table #TempAllPreviousRec

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAllRateIncreaseRec') )
		Drop table #TempAllRateIncreaseRec

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempTrafficProfile') )
		Drop table #TempTrafficProfile


GO
