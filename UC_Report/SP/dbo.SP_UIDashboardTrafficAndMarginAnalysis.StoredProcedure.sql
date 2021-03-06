USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIDashboardTrafficAndMarginAnalysis]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIDashboardTrafficAndMarginAnalysis]
As

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempTrafficAnalysis') )
		Drop table #tempTrafficAnalysis

-- Get the Traffic Minutes by Month

select 
	   Case Month(CallDate)
			When 1 then 'JAN'
			When 2 then 'FEB'
			When 3 then 'MAR'
			When 4 then 'APR'
			When 5 then 'MAY'
			When 6 then 'JUN'
			When 7 then 'JUL'
			When 8 then 'AUG'
			When 9 then'SEP'
			When 10 then 'OCT'
			When 11 then 'NOV'
			When 12 then 'DEC'
	   End as TrafficMonth,
	   convert(int ,convert(varchar(4) ,year(CallDate)) +  convert(varchar(2) ,right('0' +convert(varchar(2) ,Month(CallDate)),2))) as TrafficMonthNum,
	   convert(Decimal(19,2) ,sum(convert(Decimal(19,2),CallDuration))/60.0) Minutes
into #tempTrafficAnalysis
from tb_DailyINUnionOutFinancial
where datediff(mm , CallDate , getdate()) <=6 -- Last 6 months
and DirectionID = 1 -- Inbound Direction ( Pick one direction to prevent doubling of traffic )
group by Case Month(CallDate)
			When 1 then 'JAN'
			When 2 then 'FEB'
			When 3 then 'MAR'
			When 4 then 'APR'
			When 5 then 'MAY'
			When 6 then 'JUN'
			When 7 then 'JUL'
			When 8 then 'AUG'
			When 9 then'SEP'
			When 10 then 'OCT'
			When 11 then 'NOV'
			When 12 then 'DEC'
	   End,
convert(int ,convert(varchar(4) ,year(CallDate)) +  convert(varchar(2) ,right('0' +convert(varchar(2) ,Month(CallDate)),2)))

--select * from #tempTrafficAnalysis

-----------------------------------------------------------------------------------------
-- Create table for Exchange rate, so that all data can be converted into base currency
-----------------------------------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempExchangeRate') )
		Drop table #tempExchangeRate

	Select ExchangeRate , CurrencyID , BeginDate , Convert(datetime ,NULL) as EndDate
	into #tempExchangeRate 
	from REFERENCESERVER.UC_Reference.dbo.tb_Exchange
	order by CurrencyID , BeginDate

Update tbl1 
Set  EndDate = (
					Select Min(BeginDate) 
					From   #tempExchangeRate tbl2 
					Where  tbl1.CurrencyID = tbl2.CurrencyID 
					AND tbl1.BeginDate < tbl2.BeginDate
				) 
FROM #tempExchangeRate tbl1


-- Get the Traffic Revenue by Month

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempRevenueAnalysis') )
		Drop table #tempRevenueAnalysis

select	Case Month(CallDate)
			When 1 then 'JAN'
			When 2 then 'FEB'
			When 3 then 'MAR'
			When 4 then 'APR'
			When 5 then 'MAY'
			When 6 then 'JUN'
			When 7 then 'JUL'
			When 8 then 'AUG'
			When 9 then'SEP'
			When 10 then 'OCT'
			When 11 then 'NOV'
			When 12 then 'DEC'
	   End as TrafficMonth,
convert(int ,convert(varchar(4) ,year(CallDate)) +  convert(varchar(2) ,right('0' +convert(varchar(2) ,Month(CallDate)),2))) as TrafficMonthNum ,
convert(Decimal(19,2) ,sum(convert(Decimal(19,2) , Amount)/tbl2.ExchangeRate)) as Revenue
into #tempRevenueAnalysis
from tb_DailyINUnionOutFinancial tbl1
inner join #tempExchangeRate tbl2 on tbl1.CurrencyID = tbl2.CurrencyID
where datediff(mm , CallDate , getdate()) <=6 -- Last 6 months
and DirectionID = 1 -- Inbound
and ErrorIndicator = 0 -- All Non Error Records
group by Case Month(CallDate)
			When 1 then 'JAN'
			When 2 then 'FEB'
			When 3 then 'MAR'
			When 4 then 'APR'
			When 5 then 'MAY'
			When 6 then 'JUN'
			When 7 then 'JUL'
			When 8 then 'AUG'
			When 9 then'SEP'
			When 10 then 'OCT'
			When 11 then 'NOV'
			When 12 then 'DEC'
	   End,
convert(int ,convert(varchar(4) ,year(CallDate)) +  convert(varchar(2) ,right('0' +convert(varchar(2) ,Month(CallDate)),2)))

--select * from #tempRevenueAnalysis

-- Get the Traffic Cost by Month

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempCostAnalysis') )
		Drop table #tempCostAnalysis

select	Case Month(CallDate)
			When 1 then 'JAN'
			When 2 then 'FEB'
			When 3 then 'MAR'
			When 4 then 'APR'
			When 5 then 'MAY'
			When 6 then 'JUN'
			When 7 then 'JUL'
			When 8 then 'AUG'
			When 9 then'SEP'
			When 10 then 'OCT'
			When 11 then 'NOV'
			When 12 then 'DEC'
	   End as TrafficMonth,
convert(int ,convert(varchar(4) ,year(CallDate)) +  convert(varchar(2) ,right('0' +convert(varchar(2) ,Month(CallDate)),2))) as TrafficMonthNum,
convert(Decimal(19,2) ,sum(convert(Decimal(19,2) , Amount)/tbl2.ExchangeRate)) as Cost
into #tempCostAnalysis
from tb_DailyINUnionOutFinancial tbl1
inner join #tempExchangeRate tbl2 on tbl1.CurrencyID = tbl2.CurrencyID
where datediff(mm , CallDate , getdate()) <=6 -- Last 6 months
and DirectionID = 2 -- Outbound
and ErrorIndicator = 0 -- All Non Error Records
group by Case Month(CallDate)
			When 1 then 'JAN'
			When 2 then 'FEB'
			When 3 then 'MAR'
			When 4 then 'APR'
			When 5 then 'MAY'
			When 6 then 'JUN'
			When 7 then 'JUL'
			When 8 then 'AUG'
			When 9 then'SEP'
			When 10 then 'OCT'
			When 11 then 'NOV'
			When 12 then 'DEC'
	   End,
convert(int ,convert(varchar(4) ,year(CallDate)) +  convert(varchar(2) ,right('0' +convert(varchar(2) ,Month(CallDate)),2)))

--select * from #tempCostAnalysis

-- Create a temp table combining details from all the above three schema

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempTrafficAndMarginAnalysis') )
		Drop table #tempTrafficAndMarginAnalysis

Create table #tempTrafficAndMarginAnalysis
(
	TrafficMonth Varchar(10),
	TrafficMonthNum int,
	Minutes Decimal(19,2),
	Revenue Decimal(19,2),
	Cost Decimal(19,2),
	Margin Decimal(19,2)
)

insert into #tempTrafficAndMarginAnalysis
Select Distinct 
		Case Month(CallDate)
			When 1 then 'JAN'
			When 2 then 'FEB'
			When 3 then 'MAR'
			When 4 then 'APR'
			When 5 then 'MAY'
			When 6 then 'JUN'
			When 7 then 'JUL'
			When 8 then 'AUG'
			When 9 then'SEP'
			When 10 then 'OCT'
			When 11 then 'NOV'
			When 12 then 'DEC'
		End,
		convert(int ,convert(varchar(4) ,year(CallDate)) +  convert(varchar(2) ,right('0' +convert(varchar(2) ,Month(CallDate)),2))), 
		0, 0 ,0 ,0
from tb_DailyINUnionOutFinancial
where datediff(mm , CallDate , getdate()) <=6 -- Last 6 months

-- Update the final table with the information

update tbl1
set tbl1.Minutes = isnull(tbl2.Minutes,0),
    tbl1.Revenue = isnull(tbl3.Revenue,0),
	tbl1.Cost = isnull(tbl4.Cost,0),
	tbl1.Margin = isnull(tbl3.Revenue,0) - isnull(tbl4.Cost,0)
from #tempTrafficAndMarginAnalysis tbl1
left join #tempTrafficAnalysis tbl2 on tbl1.TrafficMonth = tbl2.TrafficMonth and tbl1.TrafficMonthNum = tbl2.TrafficMonthNum
left join #tempRevenueAnalysis tbl3 on tbl1.TrafficMonth = tbl3.TrafficMonth and tbl1.TrafficMonthNum = tbl3.TrafficMonthNum
left join #tempCostAnalysis tbl4 on tbl1.TrafficMonth = tbl4.TrafficMonth and tbl1.TrafficMonthNum = tbl4.TrafficMonthNum


-- insert the data into the master dashboard table

Delete from tb_DashboardTrafficAndMarginAnalysis

insert into tb_DashboardTrafficAndMarginAnalysis
(
   TrafficMonth ,TrafficMonthNum ,Minutes ,
   Revenue, Cost, Margin
)
select TrafficMonth ,TrafficMonthNum ,Minutes ,
       Revenue, Cost, Margin
from #tempTrafficAndMarginAnalysis


ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempTrafficAnalysis') )
		Drop table #tempTrafficAnalysis

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempExchangeRate') )
		Drop table #tempExchangeRate

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempRevenueAnalysis') )
		Drop table #tempRevenueAnalysis

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempCostAnalysis') )
		Drop table #tempCostAnalysis

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempTrafficAndMarginAnalysis') )
		Drop table #tempTrafficAndMarginAnalysis
GO
