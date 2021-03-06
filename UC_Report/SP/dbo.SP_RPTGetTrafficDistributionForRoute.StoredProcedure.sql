USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_RPTGetTrafficDistributionForRoute]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_RPTGetTrafficDistributionForRoute]
(
	@ReportRunDate datetime,
	@INServiceLevelID int,
	@DestinationID int,
	@CallTypeID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

--------------------------------------------------------
-- Based on the Report Run Date get start and end date
---------------------------------------------------------

Declare @StartDate datetime,
        @EndDate datetime

set @EndDate = @ReportRunDate
set @StartDate = dateAdd(dd , -7 , @ReportRunDate)

Begin Try

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
		-- Get the following information from the financial union
		-- tables
		-- 1. Account
		-- 2. Commercial Trunk
		-- 3. Call Duration
		-- 4. Charge Minutes
		-- 5. ASR
		-- 6. Answered
		-- 7. Seized
		-- 8. Amount (Cost)
		-- 9. CPM
		-----------------------------------------------------------

		Select tbl4.AccountAbbrv + ' / ' + tbl3.Trunk as Route,
		sum(tbl1.Answered) as Answered , sum(tbl1.Seized) as Seized , 
		convert(int ,(sum(tbl1.Answered * 1.00)/sum(tbl1.Seized)) * 100) as ASR , 
		convert(Decimal(19,2),sum(CallDuration/60.0)) as OriginalMinutes ,
		convert(Decimal(19,2),sum(ChargeDuration)) as ChargeMinutes ,
		convert(Decimal(19,2) ,Sum(Amount/tbl2.ExchangeRate)) as Cost, 
		case 
			when Sum(ChargeDuration) = 0 then 0.0000 
			else convert(decimal(19,6) ,sum(Amount/tbl2.ExchangeRate)/ Sum(ChargeDuration)) 
		end CPM
		from tb_DailyINUnionOutFinancial tbl1
		inner join #tempExchangeRate tbl2 on tbl1.CurrencyID = tbl2.CurrencyID
		inner join REFERENCESERVER.UC_Reference.dbo.tb_Trunk tbl3 on tbl1.CommercialTrunkID = tbl3.TrunkID
		inner join REFERENCESERVER.UC_Reference.dbo.tb_Account tbl4 on tbl3.AccountID = tbl4.AccountID
		Where tbl1.Directionid = 2 -- Outbound
		and tbl1.CallDate between @StartDate and @EndDate
		and tbl1.RoutingDestinationID = @DestinationID
		and tbl1.CallTypeID = @CallTypeID
		and tbl1.INServiceLevelID = @INServiceLevelID
		and tbl1.CallDate between tbl2.BeginDate and isnull(tbl2.EndDate , tbl1.CallDate)
		Group by tbl4.AccountAbbrv + ' / ' + tbl3.Trunk
		order by 5 desc

End Try

Begin Catch


		set @ErrorDescription = 'ERROR !!! Getting Traffic Distribution.' + ERROR_MESSAGE()
		set @ResultFlag = 1
		GOTO ENDPROCESS

End Catch

ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempExchangeRate') )
		Drop table #tempExchangeRate
GO
