USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIDashboardFinancial]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIDashboardFinancial]
As

Declare @StartDate Date,
        @EndDate Date,
		@MaxDate Date

-----------------------------------------------------
-- Build the dates for performing the monthly data
-- aggregation for the running month
------------------------------------------------------

set @StartDate = convert(Date,convert(varchar(4) ,Year(getdate())) + '-' + 
				 convert(varchar(2) , right('0' + convert(varchar(2) ,Month(getdate())), 2)) + '-' +
				 '01')

set @EndDate = DateAdd(dd , -1 , DateAdd(mm , 1 , @StartDate))


--select @StartDate , @EndDate

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

---------------------------------------------------------------
-- Insert record into the Temp Currency table for -1 currencyID
-- to handle scenarios where currency is not resolved
---------------------------------------------------------------

insert into #tempExchangeRate values ( 1 , -1 , @StartDate , NULL)

-----------------------------------------
-- Remove previous data from the Financial
-- dashboard schema
------------------------------------------
Truncate table tb_DashboardFinancial

-------------------------------------------------
-- Insert data into the Financial Dashboard schema
-------------------------------------------------

Insert into tb_DashboardFinancial
select * from
(
		select 'INBOUND' as TrafficDirection ,
			   sum(seized) as Seized,
			   sum(Answered) as Answered,
			   Convert(Decimal(19,2) ,sum(convert(float ,CallDuration))/60.0) as UnRoundedCallDuration,
			   sum(convert(Decimal(19,2) , ChargeDuration)) as ChargeDuration,
			   sum(convert(Decimal(19,2) , Amount)/tbl2.ExchangeRate) as Amount,
			   Case
					When sum(convert(Decimal(19,2) , ChargeDuration)) = 0 Then 0
					Else convert(Decimal(19,4) ,sum(convert(Decimal(19,2) , Amount)/tbl2.ExchangeRate)/sum(convert(Decimal(19,2) , ChargeDuration)))
			   End as Rate
		from tb_DailyINUnionOutFinancial tbl1
		inner join #tempExchangeRate tbl2 on tbl1.CurrencyID = tbl2.CurrencyID
		where calldate between @StartDate and @EndDate
		and DirectionID = 1 -- Inbound
		and ErrorIndicator = 0 -- All Non Error Records
		union
		select 'OUTBOUND' as TrafficDirection,
			   sum(Seized) as Seized,
			   sum(Answered) as Answered,
			   Convert(Decimal(19,2) ,sum(convert(Float ,CallDuration))/60.0) as UnRoundedCallDuration,
			   sum(convert(Decimal(19,2) , ChargeDuration)) as ChargeDuration,
			   sum(convert(Decimal(19,2) , Amount)/tbl2.ExchangeRate) as Amount,
			   Case
					When sum(convert(Decimal(19,2) , ChargeDuration)) = 0 Then 0
					Else convert(Decimal(19,4) ,sum(convert(Decimal(19,2) , Amount)/tbl2.ExchangeRate)/sum(convert(Decimal(19,2) , ChargeDuration)))
			   End as Rate
		from tb_DailyINUnionOutFinancial tbl1
		inner join #tempExchangeRate tbl2 on tbl1.CurrencyID = tbl2.CurrencyID
		where calldate between @StartDate and @EndDate
		and DirectionID = 2 -- Outbound
		and ErrorIndicator = 0 -- All Non Error Records
) as TBL1


if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempExchangeRate') )
		Drop table #tempExchangeRate

return 0

GO
