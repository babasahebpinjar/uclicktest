USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIDashboardHourlyQOS_XL]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIDashboardHourlyQOS_XL]
As

Declare @RunDate datetime,
        @RunCounter int = 0

--------------------------------------------------------------------
-- Considering a latency of 2 hours between CDRs from mediation to
-- dashboard refresh set the date to 2 hours before the current time
--------------------------------------------------------------------

set @RunDate = DateAdd(hh , -2 , getdate() ) 

set @RunDate = convert(datetime , (convert(date ,@RunDate)))

---------------------------------------------------------
-- insert data into the temprorary table for the whole 
-- 24 hours in a day
--------------------------------------------------------
if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempFinalResult') )
		Drop table #TempFinalResult

Create table #TempFinalResult
(
	CallHour varchar(6),
	ASR int,
	TotalMinutes Decimal(19,2),
	MHT DEcimal(19,2),
	ALOC Decimal(19,2)
)

While ( @RunCounter <=23 )
Begin

		Insert into #TempFinalResult
		select right('0' + convert(varchar(2) ,@RunCounter) ,2) + ':' + '00',
		       0 , 0.00 , 0.00 , 0.00

        set @RunCounter = @RunCounter + 1

End

------------------------------------------------
-- Extract the data from the QOS schema
-------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDataSet') )
		Drop table #TempDataSet

Select right('0' + convert(varchar(2) ,tbl1.CallHour) ,2) + ':' + '00' as CallHour ,
convert(int ,(convert(Decimal(19,2) , sum(tbl1.Answered)) * 100.0 )/sum(tbl1.Seized)) as ASR ,
convert(Decimal(19,2),sum(CallDuration/60.0)) TotalMinutes ,
 Case 
     When sum(tbl1.Answered) = 0 then 0
     Else convert(decimal(19,2) ,(convert(Decimal(19,2),sum((CircuitDuration - CallDuration)/60.0)))/sum(tbl1.Answered))
 End as MHT ,
 Case
     When sum(tbl1.Answered) = 0 then 0
     Else convert(decimal(19,2) ,(convert(Decimal(19,2),sum(CallDuration/60.0)))/sum(tbl1.Answered))
 End as ALOC
 into #tempDataSet
 from tb_HourlyINCrossOutTrafficMart tbl1
 where CallDate = @RunDate
 group by right('0' + convert(varchar(2) ,tbl1.CallHour) ,2) + ':' + '00'

----------------------------------------------------------
-- Update the data in the Final Result Set based on
-- Extracted data
-----------------------------------------------------------

update tbl1
set ASR = tbl2.ASR,
    TotalMinutes = tbl2.TotalMinutes,
	MHT = tbl2.MHT,
	ALOC = tbl2.ALOC
from #TempFinalResult tbl1
inner join #tempDataSet tbl2 on tbl1.CallHour = tbl2.CallHour

-------------------------------------------------
-- Update the Dashboard schema with the details
-------------------------------------------------

Delete from tb_DashboardHourlyQOS

insert into tb_DashboardHourlyQOS
(
	CallHour,
	ASR,
	TotalMinutes,
	MHT,
	ALOC
)
select 	CallHour,
		ASR,
		TotalMinutes,
		MHT,
		ALOC
from #TempFinalResult


ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempFinalResult') )
		Drop table #TempDataSet

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempFinalResult') )
		Drop table #TempFinalResult
GO
