USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIDashboardTerminatingTraffic]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIDashboardTerminatingTraffic]
(
	@DateOffset int
)
As

Declare @StartDate datetime,
	    @EndDate datetime,
		@RunDate datetime

set @EndDate = convert(datetime,convert(date , getdate()))
set @Startdate  = DateAdd(dd ,(@DateOffset * -1) , @EndDate)

-------------------------------------------------------
-- Create a temporary table with all the Call Date and
-- Service level Records
--------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempFinalResultSet') )
		Drop table #tempFinalResultSet

Create table #tempFinalResultSet
(
	CallDate datetime,
	ServiceLevel varchar(100),
	TotalMinutes Decimal(19,2)
)

set @RunDate = @StartDate

While ( @RunDate <=  @EndDate )
Begin

		insert into #tempFinalResultSet
		select @RunDate , ServiceLevel , 0.00
		from REFERENCESERVER.UC_REference.dbo.tb_ServiceLevel
		where DirectionID = 1
		and ServiceLevelID > 0

		set @RunDate = DateAdd(dd ,1 ,  @RunDate)

End

------------------------------------------------------------
-- Extract data for Termination Scenarios by Call Date &
-- Service Level
-------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempDatatSet') )
		Drop table #tempDatatSet

select tbl1.CallDate,
       tbl2.ServiceLevel,
       convert(Decimal(19,2),sum(tbl1.CallDuration/60.0)) as TotalMinutes
into #tempDatatSet
from tb_DailyINUnionOutFinancial tbl1
inner join REFERENCESERVER.UC_REference.dbo.tb_ServiceLevel tbl2 on
                  tbl1.INServiceLevelID = tbl2.ServiceLevelID
Where tbl1.CallDate between @StartDate and @EndDate
and tbl1.DirectionID = 1 -- Inbound for Termination Traffic
Group by tbl1.CallDate , tbl2.ServiceLevel

---------------------------------------------------
-- Update the data in the Final Result Set table
-- for all the dates where traffic exists
---------------------------------------------------

update tbl1
set TotalMinutes = tbl2.TotalMinutes
from #tempFinalResultSet tbl1
inner join #tempDatatSet tbl2 on tbl1.CallDate = tbl2.CallDate
                           and tbl1.ServiceLevel = tbl2.ServiceLevel


----------------------------------------------
-- Update the Schema for the dashboard graph
----------------------------------------------

Delete from tb_DashboardGraphTerminatingTraffic

insert into tb_DashboardGraphTerminatingTraffic
(
	CallDate,
	ServiceLevel,
	TotalMinutes
)
select CallDate,
	   ServiceLevel,
	   TotalMinutes 
from #tempFinalResultSet

ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempFinalResultSet') )
		Drop table #tempFinalResultSet

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempDatatSet') )
		Drop table #tempDatatSet
GO
