USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIDashboardOrigCostByCarrierCodeAndCountry]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIDashboardOrigCostByCarrierCodeAndCountry]
(
	@DateOffset int,
	@TopN int
)
As

Declare @StartDate datetime,
	    @EndDate datetime,
		@SQLStr nvarchar(Max)

set @EndDate = convert(datetime,convert(date , getdate()))
set @Startdate  = DateAdd(dd ,(@DateOffset * -1) , @EndDate)

if ( ( @TopN is NULL ) or ( @TopN <= 0 ) )
	set @TopN = 10
-----------------------------------------------------------------------------------------
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

---------------------------------------------------------------
-- Insert record into the Temp Currency table for -1 currencyID
-- to handle scenarios where currency is not resolved
---------------------------------------------------------------

insert into #tempExchangeRate values ( 1 , -1 , @StartDate , NULL)

------------------------------------------------------------
-- Extract data for Termination Scenarios by Account and 
-- Commercial Trunk
-------------------------------------------------------------

Select isnull(tbl2.AccountAbbrv, '****') + '/' + isnull(tbl3.Trunk, '****') as CarrierCode,
       isnull(tbl6.Country , '****') as Country,
sum(tbl1.Answered) as Answered , sum(tbl1.Seized) as Seized ,
convert(int ,(sum(tbl1.Answered * 1.00)/sum(tbl1.Seized)) * 100) as ASR ,
convert(Decimal(19,2),sum(CallDuration/60.0)) as OriginalMinutes ,
convert(Decimal(19,2),sum(ChargeDuration)) as ChargeMinutes ,
convert(Decimal(19,2) ,Sum(Amount/tbl4.ExchangeRate)) as Cost,
case
   when Sum(ChargeDuration) = 0 then 0.0000
   else convert(decimal(19,6) ,sum(Amount/tbl4.ExchangeRate)/ Sum(ChargeDuration))
end as CPM
into #tempFinalResultSet
from tb_DailyINUnionOutFinancial tbl1
left join REFERENCESERVER.UC_REference.dbo.tb_Account tbl2 on tbl1.ACcountID = tbl2.AccountID
left Join REFERENCESERVER.UC_REference.dbo.tb_trunk tbl3 on tbl1.CommercialTrunkID = tbl3.TrunkID 
inner join #tempExchangeRate tbl4 on tbl1.CurrencyID = tbl4.CurrencyID
left join REFERENCESERVER.UC_REference.dbo.tb_Destination tbl5 on tbl1.RoutingDestinationID = tbl5.DestinationID
left join REFERENCESERVER.UC_REference.dbo.tb_Country tbl6 on tbl5.CountryID = tbl6.CountryID
where tbl1.CallDate between @StartDate and @EndDate
and tbl1.DirectionId = 2 -- Outbound for Origination Traffic
Group by  isnull(tbl2.AccountAbbrv, '****') + '/' + isnull(tbl3.Trunk, '****'),
          isnull(tbl6.Country , '****')

----------------------------------------------
-- Update the Schema for the dashboard table
----------------------------------------------

Delete from tb_DashboardOrigCostByCarrierCodeAndCountry

set @SQLStr = 
       'Select Top ' + convert(varchar(10) , @TopN) + char(10) +
	   ' CarrierCode , Country ,Answered, Seized , ASR , OriginalMinutes ,' + char(10) +
	   ' ChargeMinutes , Cost , CPM ' + char(10) +
	   'From #tempFinalResultSet' + char(10) +
	   'where OriginalMinutes > 0' + char(10) +	
	   'Order by OriginalMinutes desc , Cost desc'


insert into tb_DashboardOrigCostByCarrierCodeAndCountry
Exec(@SQLStr)


ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempExchangeRate') )
		Drop table #tempExchangeRate

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempFinalResultSet') )
		Drop table #tempFinalResultSet
GO
