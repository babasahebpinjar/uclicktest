USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSCalculatePrepaidPastPeriodBalance]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_BSCalculatePrepaidPastPeriodBalance] As

Declare @CurrPeriod int 
Declare @CurrRunDate date =  dateadd(mm , -1 ,convert(date ,substring(convert(varchar(10) , getdate(),120) , 1,7) + '-' + '01'))

set @CurrPeriod = convert(int,replace(convert(varchar(7) , @CurrRunDate , 120), '-' , ''))

-------------------------------------------------------------------------------------------
-- Create table for Exchange rate, so that all data can be converted into base currency
-----------------------------------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempExchangeRate') )
		Drop table #tempExchangeRate

	Select ExchangeRate , CurrencyID , BeginDate , COnvert(datetime ,NULL) as EndDate
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

-- Select 'Debug Exchange Rate Start
-- Select  * from #tempExchangeRate
-- Select 'Debug Exchange Rate End

----------------------------------------------------------------
-- Get Amount per account per period from Daily Financial Mart
----------------------------------------------------------------

select AccountID ,
	   Convert(varchar(4) ,year(CallDate)) + 
	   right('0' + convert(varchar(2), month(calldate)),2) as TrafficPeriod,
       Convert(Decimal(19,2) ,sum(Amount/forex.ExchangeRate)) as Amount
into #tempAmountByPeriod
from tb_DailyINUnionOutFinancial findata
inner join #tempExchangeRate forex on findata.CurrencyID = forex.CurrencyID
									and
									  findata.CallDate between forex.BeginDate and isnull(forex.EndDate , findata.CallDate)
where convert(int ,Convert(varchar(4) ,year(CallDate)) + right('0' + convert(varchar(2), month(calldate)),2)) < @CurrPeriod
and findata.directionID = 1
and findata.AccountID > 0
and findata.currencyID > 0 -- All Records where Amount is more than zero
and findata.Answered > 0 -- Pick up all the records where there is atleast one answered call
and findata.ErrorIndicator = 0
group by AccountID ,
	   Convert(varchar(4) ,year(CallDate)) + 
	   right('0' + convert(varchar(2), month(calldate)),2)

-- Select 'Debug Amount By Period Start
-- Select  * from #tempAmountByPeriod
-- Select 'Debug Amount By Period End


----------------------------------------------------------------------------
-- Get data for all accounts that have been prepaid across different periods
----------------------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempAccountAndPeriod') )
		Drop table #tempAccountAndPeriod

select AccountID , Period
into #tempAccountAndPeriod
from ReferenceServer.UC_Reference.dbo.tb_AccountMode
where AccountModeTypeID = -2

-----------------------------------------------------------
-- Filter data for all the Account and Prepaid periods
-----------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempPrepaidPastBalance') )
		Drop table #tempPrepaidPastBalance

Select tbl1.*
into #tempPrepaidPastBalance
from #tempAmountByPeriod tbl1
inner join #tempAccountAndPeriod tbl2 on tbl1.AccountID = tbl2.AccountID and tbl1.TrafficPeriod = tbl2.Period

---------------------------------------------------------------------------
-- If there are no records for past period then exit, else update the
-- schema with new amounts
---------------------------------------------------------------------------

if not exists (select 1 from #tempPrepaidPastBalance) -- There are no past prepaid balances
Begin

		GOTO ENDPROCESS

End

----------------------------------------------------------------------------
-- Update the data in the schema for all accounts and periods, where the
-- Amount has changed
----------------------------------------------------------------------------

update tbl2
set Amount = tbl2.Amount
from #tempPrepaidPastBalance tbl1
inner join tb_PrepaidPastBalance tbl2 on tbl1.AccountID = tbl2.AccountID and tbl1.TrafficPeriod = tbl2.Period
where tbl1.Amount <> tbl2.Amount

-------------------------------------------------------------------------
-- Insert records in the schema for Account and Period, where no data
-- exists previously
-------------------------------------------------------------------------

insert into tb_PrepaidPastBalance (AccountID , Period, Amount)
select tbl1.AccountID , tbl1.TrafficPeriod , tbl1.Amount
from #tempPrepaidPastBalance tbl1
left join tb_PrepaidPastBalance tbl2 on tbl1.AccountID = tbl2.AccountID and tbl1.TrafficPeriod = tbl2.Period
where tbl2.AccountID is NULL


ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempExchangeRate') )
		Drop table #tempExchangeRate

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempAmountByPeriod') )
		Drop table #tempAmountByPeriod
GO
