USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_FinancialReporting_AGS]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_FinancialReporting_AGS] 
(
	@StartDate Date,
    @EndDate Date,
	@Documentdate varchar(10),
	@ExchangeRate Decimal(19,4)
)
As

--Declare @StartDate Date,
--		@EndDate Date,
--		@Documentdate varchar(10),
--		@ExchangeRate Decimal(19,4)
    
--set @StartDate = '2019-11-01'
--set @EndDate = '2019-11-30'
--set @Documentdate = '30/11/19'
--set @ExchangeRate = 1.3677

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempTrafficDetail') )	
	Drop table #TempTrafficDetail

Select *
into #TempTrafficDetail
from
(
		select tbl1.AccountID, tbl3.Destination , tbl4.Country, tbl5.ServiceLevel as INRouteclass,
			   isnull(tbl7.Assignment, 'NA')  as Account,
			   isnull(tbl7.Country, 'NA')  as CarrierCountry,
			   Case
						When tbl1.AccountID in (2245,2248,2256,2262,2275) -- Axiata Related Parties
								then 'HUB REV RP'
						Else 'HUB REV'
			   End as Product,
			   convert(Decimal(19,2) ,sum(convert(decimal(19,4) ,RoundedCallDuration/60.0))) as Minutes,
			   Case
					When tbl1.CurrencyID = 1013 -- USD 
						then convert(decimal(19,2) ,sum(Amount))
					Else 0
			   End as Currency_USD,
			   Case
					When tbl1.CurrencyID <> 1013 -- Not USD 
						then convert(decimal(19,2) ,sum(Amount))
					Else 0
			   End as Currency_SGD,
			   convert(decimal(19,4),sum(Amount)/sum(convert(decimal(19,4) ,RoundedCallDuration/60.0))) as Rate,
			   isnull(tbl7.RevenueStatement, 'NA') as StatementNumber,
			   'Statement Issued' as Statementstatus,
			   'Inbound' as Direction , isnull(tbl6.Destination, '***') as SettlementDestination
		from tb_DailyINUnionOutFinancial tbl1
		inner join ReferenceServer.UC_Reference.dbo.tb_account tbl2 on tbl1.AccountID = tbl2.AccountID
		inner join ReferenceServer.UC_Reference.dbo.tb_destination tbl3 on tbl1.RoutingDestinationID = tbl3.DestinationID
		inner join ReferenceServer.UC_Reference.dbo.tb_Country tbl4 on tbl3.Countryid = tbl4.CountryID
		inner join ReferenceServer.UC_Reference.dbo.tb_ServiceLevel tbl5 on tbl1.INServiceLevelID = tbl5.ServiceLevelID
		left join ReferenceServer.UC_Reference.dbo.tb_destination tbl6 on tbl1.SettlementDestinationID = tbl6.DestinationID
		left join tb_BillingAccountInfo tbl7 on tbl1.AccountID = tbl7.AccountID
		where Calldate between @StartDate and @EndDate
		and tbl3.NumberplanID = -1 -- Routing Destinations
		and tbl1.ErrorIndicator = 0 -- All non Error Traffic
		and tbl1.CallDuration > 0 -- All Successful Calls
		and tbl1.DirectionID = 1 -- All Inbound Revenue traffic
		and tbl5.DirectionID = 1 -- Inbound Service Levels
		and tbl4.Country <> 'Singapore'  -- Legally exclude any Singapore traffic
		group by tbl1.AccountID,tbl3.Destination , tbl4.Country, tbl5.ServiceLevel, tbl1.currencyID, 
				 isnull(tbl7.Assignment, 'NA'), isnull(tbl7.Country, 'NA'),  isnull(tbl7.RevenueStatement, 'NA'),

		Case
				When tbl1.AccountID in (2245,2248,2256,2262,2275) -- Axiata Related Parties
						then 'HUB REV RP'
				Else 'HUB REV'
		End , isnull(tbl6.Destination , '***')

		UNION

		select  tbl1.AccountID, tbl3.Destination , tbl4.Country, tbl5.ServiceLevel as INRouteclass,
			   isnull(tbl7.Assignment, 'NA')  as Account,
			   isnull(tbl7.Country, 'NA')  as CarrierCountry,
			   Case
						When tbl1.AccountID in (2245,2248,2256,2262,2275) -- Axiata Related Parties
								then 'HUB REV RP'
						Else 'HUB REV'
			   End as Product,
			   convert(Decimal(19,2) ,sum(convert(decimal(19,4) ,CallDuration/60.0))) as Minutes,
			   0 as Currency_USD , 0 as Currency_SGD, 0 as Rate	,  
			   'Not Applicable' as StatementNumber,
			   'Not Applicable' as Statementstatus,
			   'Inbound' as Direction , isnull(tbl6.Destination, '***') as SettlementDestination
		from tb_DailyINUnionOutFinancial tbl1
		inner join ReferenceServer.UC_Reference.dbo.tb_account tbl2 on tbl1.AccountID = tbl2.AccountID
		inner join ReferenceServer.UC_Reference.dbo.tb_destination tbl3 on tbl1.RoutingDestinationID = tbl3.DestinationID
		inner join ReferenceServer.UC_Reference.dbo.tb_Country tbl4 on tbl3.Countryid = tbl4.CountryID
		inner join ReferenceServer.UC_Reference.dbo.tb_ServiceLevel tbl5 on tbl1.INServiceLevelID = tbl5.ServiceLevelID
		left join ReferenceServer.UC_Reference.dbo.tb_destination tbl6 on tbl1.SettlementDestinationID = tbl6.DestinationID
		left join tb_BillingAccountInfo tbl7 on tbl1.AccountID = tbl7.AccountID
		where Calldate between @StartDate and @EndDate
		and tbl3.NumberplanID = -1 -- Routing Destinations
		and tbl1.ErrorIndicator = 1 -- All Error Traffic
		and tbl1.CallDuration > 0 -- All Successful Calls
		and tbl1.DirectionID = 1 -- All Inbound Revenue traffic
		and tbl5.DirectionID = 1 -- Inbound Service Levels
		and tbl4.Country <> 'Singapore'  -- Legally exclude any Singapore traffic
		group by tbl1.AccountID,tbl3.Destination , tbl4.Country, tbl5.ServiceLevel,  isnull(tbl7.Assignment, 'NA'), isnull(tbl7.Country, 'NA'),
		Case
				When tbl1.AccountID in (2245,2248,2256,2262,2275) -- Axiata Related Parties
						then 'HUB REV RP'
				Else 'HUB REV'
		End, isnull(tbl6.Destination , '***')

		UNION

		select tbl1.AccountID,tbl3.Destination , tbl4.Country, tbl5.ServiceLevel as INRouteclass,
			   isnull(tbl7.Assignment, 'NA')  as Account,
			   isnull(tbl7.Country, 'NA')  as CarrierCountry,
			   Case
						When tbl1.AccountID in (2245,2248,2256,2262,2275) -- Axiata Related Parties
								then 'HUB EXP RP'
						Else 'HUB EXP'
			   End as Product,
			   convert(Decimal(19,2) ,sum(convert(decimal(19,4) ,RoundedCallDuration/60.0))) as Minutes,
			   Case
					When tbl1.CurrencyID = 1013 -- USD 
						then convert(decimal(19,2) ,sum(Amount))
					Else 0
			   End as Currency_USD,
			   Case
					When tbl1.CurrencyID <> 1013 -- Not USD 
						then convert(decimal(19,2) ,sum(Amount))
					Else 0
			   End as Currency_SGD,
			   convert(decimal(19,4),sum(Amount)/sum(convert(decimal(19,4) ,RoundedCallDuration/60.0))) as Rate,
			   isnull(tbl7.CostStatement, 'NA') as StatementNumber,
			   'Statement Issued' as Statementstatus,
			   'Outbound' as Direction , isnull(tbl6.Destination, '***') as SettlementDestination
		from tb_DailyINUnionOutFinancial tbl1
		inner join ReferenceServer.UC_Reference.dbo.tb_account tbl2 on tbl1.AccountID = tbl2.AccountID
		inner join ReferenceServer.UC_Reference.dbo.tb_destination tbl3 on tbl1.RoutingDestinationID = tbl3.DestinationID
		inner join ReferenceServer.UC_Reference.dbo.tb_Country tbl4 on tbl3.Countryid = tbl4.CountryID
		inner join ReferenceServer.UC_Reference.dbo.tb_ServiceLevel tbl5 on tbl1.INServiceLevelID = tbl5.ServiceLevelID
		left join ReferenceServer.UC_Reference.dbo.tb_destination tbl6 on tbl1.SettlementDestinationID = tbl6.DestinationID
		left join tb_BillingAccountInfo tbl7 on tbl1.AccountID = tbl7.AccountID
		where Calldate between @StartDate and @EndDate
		and tbl3.NumberplanID = -1 -- Routing Destinations
		and tbl1.ErrorIndicator = 0 -- All non Error Traffic
		and tbl1.CallDuration > 0 -- All Successful Calls
		and tbl1.DirectionID = 2 -- All Outbound Cost traffic
		and tbl5.DirectionID = 1 -- Inbound Service Levels
		and tbl4.Country <> 'Singapore'  -- Legally exclude any Singapore traffic
		group by tbl1.AccountID,tbl3.Destination , tbl4.Country, tbl5.ServiceLevel, tbl1.currencyID, 
				 isnull(tbl7.Assignment, 'NA'), isnull(tbl7.Country, 'NA'),  isnull(tbl7.CostStatement, 'NA'),

		Case
				When tbl1.AccountID in (2245,2248,2256,2262,2275) -- Axiata Related Parties
						then 'HUB EXP RP'
				Else 'HUB EXP'
		End, isnull(tbl6.Destination , '***')

		UNION

		select tbl1.AccountID, tbl3.Destination , tbl4.Country, tbl5.ServiceLevel as INRouteclass,
			   isnull(tbl7.Assignment, 'NA')  as Account,
			   isnull(tbl7.Country, 'NA')  as CarrierCountry,
			   Case
						When tbl1.AccountID in (2245,2248,2256,2262,2275) -- Axiata Related Parties
								then 'HUB EXP RP'
						Else 'HUB EXP'
			   End as Product,
			   convert(Decimal(19,2) ,sum(convert(decimal(19,4) ,CallDuration/60.0))) as Minutes,
			   0 as Currency_USD , 0 as Currency_SGD, 0 as Rate	,  
			   'Not Applicable' as StatementNumber,
			   'Not Applicable' as Statementstatus,
			   'Outbound' as Direction , isnull(tbl6.Destination, '***') as SettlementDestination
		from tb_DailyINUnionOutFinancial tbl1
		inner join ReferenceServer.UC_Reference.dbo.tb_account tbl2 on tbl1.AccountID = tbl2.AccountID
		inner join ReferenceServer.UC_Reference.dbo.tb_destination tbl3 on tbl1.RoutingDestinationID = tbl3.DestinationID
		inner join ReferenceServer.UC_Reference.dbo.tb_Country tbl4 on tbl3.Countryid = tbl4.CountryID
		inner join ReferenceServer.UC_Reference.dbo.tb_ServiceLevel tbl5 on tbl1.INServiceLevelID = tbl5.ServiceLevelID
		left join ReferenceServer.UC_Reference.dbo.tb_destination tbl6 on tbl1.SettlementDestinationID = tbl6.DestinationID
		left join tb_BillingAccountInfo tbl7 on tbl1.AccountID = tbl7.AccountID
		where Calldate between @StartDate and @EndDate
		and tbl3.NumberplanID = -1 -- Routing Destinations
		and tbl1.ErrorIndicator = 1 -- All Error Traffic
		and tbl1.CallDuration > 0 -- All Successful Calls
		and tbl1.DirectionID = 2 -- All Inbound Revenue traffic
		and tbl5.DirectionID = 1 -- Inbound Service Levels
		and tbl4.Country <> 'Singapore'  -- Legally exclude any Singapore traffic
		group by tbl1.AccountID,tbl3.Destination , tbl4.Country, tbl5.ServiceLevel,  isnull(tbl7.Assignment, 'NA'), isnull(tbl7.Country, 'NA'),
		Case
				When tbl1.AccountID in (2245,2248,2256,2262,2275) -- Axiata Related Parties
						then 'HUB EXP RP'
				Else 'HUB EXP'
		End, isnull(tbl6.Destination , '***')
) as TBL1

------------------------------------------------------------
-- Update the PRODUCT field for traffic based on whether the
-- Account is Post or Pre Paid in the closing month
------------------------------------------------------------
update tbl1
set Product = 
	Case
		When tbl1.Direction = 'Inbound' and tbl2.AccountModeTypeID = -2 then 'HUB REV PR'
		When tbl1.Direction = 'Outbound' and tbl2.AccountModeTypeID = -2 then 'HUB EXP PR'
		Else Product
	End
from #TempTrafficDetail tbl1
inner join ReferenceServer.UC_Reference.dbo.tb_AccountMode tbl2 on tbl1.AccountID = tbl2.AccountID
where tbl2.Period = convert(int ,convert(varchar(4) , year(@EndDate)) + right('0' + convert(varchar(2) , month(@EndDate)) ,2))



Select Product , INRouteClass, Destination, SettlementDestination ,Country, Account,
       CarrierCountry, Minutes , Currency_USD ,Currency_SGD,  
	   Rate, StatementNumber , StatementStatus, Direction
from #TempTrafficDetail

-------------------------------------------
-- MS DYNAMICS Report For Revenue and Cost
-------------------------------------------

-- Revenue Report

						-----------------------------------------------------------------
						-- *************** MS DYNAMICS REVENUE REPORTS ***************
						-----------------------------------------------------------------

------------------------
-- POST PAID ACCOUNTS
------------------------ 

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempMSDynamicsRevenuePostPaid') )	
	Drop table #TempMSDynamicsRevenuePostPaid

select @Documentdate as Date,
       'Customer' as 'Account Type',
	   tbl2.CustomerCode as 'Account',
	   tbl1.StatementNumber as 'Invoice No',
	   @Documentdate as 'Document date',
	   tbl1.Account + '-' + tbl1.Product + '-' + replace(@Documentdate , '/' , '') as Description,
	   'B18000' as 'Financial Dimension - BudgetCentre',
	   'ISVH'as 'Financial Dimension - Product',
	   'P22100' as 'Financial Dimension - CostCenter',
	   'SG-001' as 'Financial Dimension - Project',
	   'NON-SBO(I)' as 'Financial Dimension - SG_BOI',
	   'USD' as 'Currency',
	   'ZR' as 'Sales tax group',
	   'All' as 'Item Sales tax group',
	   0 as 'Tax Amount',
	   sum(Currency_USD) as 'Debit Amount',
	   '' as 'Credit Amount',
	   'Ledger' as 'Offset account type',
		Case
				When tbl1.AccountID in (2245,2248,2256,2262,2275) -- Axiata Related Parties
						then '61010103'
				Else '61010104'
		End as 'Offset account',
	   'B18000' as 'Offset account – BudgetCentre',
	   'ISVH' as 'Offset account – Product',
	   'P22100' as 'Offset account – Cost center',
	   'SG-001' as 'Offset account – Project',
	   'NON-SBO(I)' as 'Offset Account - SG_BOI'
into #TempMSDynamicsRevenuePostPaid
from #TempTrafficDetail tbl1
inner join tb_BillingAccountInfo tbl2 on tbl1.Account = tbl2.Assignment
where statementNumber <> 'Not Applicable'
and Direction = 'Inbound'
and Product in ('HUB REV' , 'HUB REV RP') -- Segregating Post Paid account revenue
group by tbl1.AccountID,tbl2.CustomerCode, tbl1.StatementNumber,
		tbl1.Account + '-' + tbl1.Product + '-' + replace(@Documentdate , '/' , '')
having sum(Currency_USD) > 0

select * from #TempMSDynamicsRevenuePostPaid

------------------------
-- PRE PAID ACCOUNTS
------------------------ 

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempMSDynamicsRevenuePrePaid') )	
	Drop table #TempMSDynamicsRevenuePrePaid

select @Documentdate as Date,
       'Ledger' as 'Account Type',
	   '30610102' as 'Account', -- use hardcoded GL Code instead of Customer GL Code
	   tbl1.StatementNumber as 'Invoice No',
	   @Documentdate as 'Document date',
	   tbl1.Account + '-' + tbl1.Product + '-' + replace(@Documentdate , '/' , '') as Description,
	   'B18000' as 'Financial Dimension - BudgetCentre',
	   'ISVH'as 'Financial Dimension - Product',
	   'P22100' as 'Financial Dimension - CostCenter',
	   'SG-002' as 'Financial Dimension - Project',
	   'NON-SBO(I)' as 'Financial Dimension - SG_BOI',
	   'USD' as 'Currency',
	   '' as 'Sales tax group',
	   '' as 'Item Sales tax group',
	   '' as 'Tax Amount',
	   sum(Currency_USD) as 'Debit Amount',
	   '' as 'Credit Amount',
	   'Ledger' as 'Offset account type',
		'61010105' as 'Offset account', -- Use hard coded GL Code and no need to handle for Related Party
	   'B18000' as 'Offset account – BudgetCentre',
	   'ISVH' as 'Offset account – Product',
	   'P22100' as 'Offset account – Cost center',
	   'SG-002' as 'Offset account – Project',
	   'NON-SBO(I)' as 'Offset Account - SG_BOI'
into #TempMSDynamicsRevenuePrePaid
from #TempTrafficDetail tbl1
inner join tb_BillingAccountInfo tbl2 on tbl1.Account = tbl2.Assignment
where statementNumber <> 'Not Applicable'
and Direction = 'Inbound'
and Product = 'HUB REV PR' -- Segregating Pre Paid account revenue
group by tbl1.AccountID,tbl2.CustomerCode, tbl1.StatementNumber,
		tbl1.Account + '-' + tbl1.Product + '-' + replace(@Documentdate , '/' , '')
having sum(Currency_USD) > 0

select * from #TempMSDynamicsRevenuePrePaid

-- Cost Report

						-----------------------------------------------------------------
						-- *************** MS DYNAMICS COST REPORTS ***************
						-----------------------------------------------------------------

----------------------
-- POST PAID ACCOUNTS
----------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempMSDynamicsExpensePostPaid') )	
	Drop table #TempMSDynamicsExpensePostPaid

select @Documentdate as Date,
       'Vendor' as 'Account Type',
	   tbl2.VendorCode as 'Account',
	   tbl1.StatementNumber as 'Invoice No',
	   @Documentdate as 'Document date',
	   tbl1.Account + '-' + tbl1.Product + ' ACC' + '-' + replace(@Documentdate , '/' , '') as Description,
	   'B18000' as 'Financial Dimension - BudgetCentre',
	   'ISVH'as 'Financial Dimension - Product',
	   'P22100' as 'Financial Dimension - CostCenter',
	   'SG-001' as 'Financial Dimension - Project',
	   'NON-SBO(I)' as 'Financial Dimension - SG_BOI',
	   'USD' as 'Currency',
	   '' as 'Sales tax group',
-- Change requested by Alia on 23rd July 2019
-- Make Sales tax group blank for outbound interface file
	  -- 'ZP' as 'Sales tax group',
	   '' as 'Item Sales tax group',
-- Change requested by Alia on 23rd July 2019
-- Make Item sales tax group blank for outbound interface file
	  -- 'All' as 'Item Sales tax group',
-- Change requested by Alia on 23rd July 2019
-- Make Tax Amount blank for outbound interface file
	   '' as 'Tax Amount',
	   --0 as 'Tax Amount',
	   '' as 'Debit Amount',
	   sum(Currency_USD) as 'Credit Amount',
	   'Ledger' as 'Offset account type',
		Case
				When tbl1.AccountID in (2245,2248,2256,2262,2275) -- Axiata Related Parties
						then '71010102'
				Else '71010103'
		End as 'Offset account',
	   'B18000' as 'Offset account – BudgetCentre',
	   'ISVH' as 'Offset account – Product',
	   'P22100' as 'Offset account – Cost center',
	   'SG-001' as 'Offset account – Project',
	   'NON-SBO(I)' as 'Offset Account - SG_BOI'
into #TempMSDynamicsExpensePostPaid
from #TempTrafficDetail tbl1
inner join tb_BillingAccountInfo tbl2 on tbl1.Account = tbl2.Assignment
where statementNumber <> 'Not Applicable'
and Direction = 'Outbound'
and Product in ('HUB EXP RP' , 'HUB EXP')
group by tbl1.AccountId,tbl2.VendorCode, tbl1.StatementNumber,
		tbl1.Account + '-' + tbl1.Product + ' ACC' +'-' + replace(@Documentdate , '/' , '')
having sum(Currency_USD) > 0

Select * From #TempMSDynamicsExpensePostPaid

----------------------
-- PRE PAID ACCOUNTS
----------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempMSDynamicsExpensePrePaid') )	
	Drop table #TempMSDynamicsExpensePrePaid

select @Documentdate as Date,
       'Vendor' as 'Account Type',
	   tbl2.VendorCode as 'Account',
	   tbl1.StatementNumber as 'Invoice No',
	   @Documentdate as 'Document date',
	   tbl1.Account + '-' + tbl1.Product + ' ACC' + '-' + replace(@Documentdate , '/' , '') as Description,
	   'B18000' as 'Financial Dimension - BudgetCentre',
	   'ISVH'as 'Financial Dimension - Product',
	   'P22100' as 'Financial Dimension - CostCenter',
	   'SG-002' as 'Financial Dimension - Project',
	   'NON-SBO(I)' as 'Financial Dimension - SG_BOI',
	   'USD' as 'Currency',
	   '' as 'Sales tax group',
-- Change requested by Alia on 23rd July 2019
-- Make Sales tax group blank for outbound interface file
	  -- 'ZP' as 'Sales tax group',
	   '' as 'Item Sales tax group',
-- Change requested by Alia on 23rd July 2019
-- Make Item sales tax group blank for outbound interface file
	  -- 'All' as 'Item Sales tax group',
-- Change requested by Alia on 23rd July 2019
-- Make Tax Amount blank for outbound interface file
	   '' as 'Tax Amount',
	   --0 as 'Tax Amount',
	   '' as 'Debit Amount',
	   sum(Currency_USD) as 'Credit Amount',
	   'Ledger' as 'Offset account type',
		'71010104' as 'Offset account', --Hard Coded Value as Pre paid accounts will not be Related Parties
	   'B18000' as 'Offset account – BudgetCentre',
	   'ISVH' as 'Offset account – Product',
	   'P22100' as 'Offset account – Cost center',
	   'SG-002' as 'Offset account – Project',
	   'NON-SBO(I)' as 'Offset Account - SG_BOI'
into #TempMSDynamicsExpensePrePaid
from #TempTrafficDetail tbl1
inner join tb_BillingAccountInfo tbl2 on tbl1.Account = tbl2.Assignment
where statementNumber <> 'Not Applicable'
and Direction = 'Outbound'
and Product  = 'HUB EXP PR'
group by tbl1.AccountId,tbl2.VendorCode, tbl1.StatementNumber,
		tbl1.Account + '-' + tbl1.Product + ' ACC' +'-' + replace(@Documentdate , '/' , '')
having sum(Currency_USD) > 0

Select * From #TempMSDynamicsExpensePrePaid

-----------------------------------------------------------
-- GST Report for all the Revenue Data and Advance Payments
-----------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempGSTReport') )	
	Drop table #TempGSTReport

select [Document Date] as 'INVOICE DATE',
	   [Invoice No] as 'INVOICE NO',
	   [Description] as 'DESCRIPTION OF TRANSACTION',
	   [Tax Amount] + [Debit Amount] as 'INVOICE AMOUNT IN DOC CURRENCY',
	   Currency as 'DOC CURRENCY',
	   Case
			When Currency = 'SGD' Then [Tax Amount] + [Debit Amount]
			When Currency = 'USD' Then convert(Decimal(19,2) ,([Tax Amount] + [Debit Amount]) * @ExchangeRate)
	   End as 'INVOICE AMOUNT LOCAL CURRENCY (SGD)',
	   Case
			When [Tax Amount] = 0 Then NULL
			Else convert(Decimal(19,2),[Debit Amount] * @ExchangeRate)
	   End as 'TOTAL TAXABLE AMOUNT',
	   Case
			When [Tax Amount] = 0 Then NULL
			Else convert(Decimal(19,2) ,[Tax Amount] * @ExchangeRate)
	   End as 'TAX AMOUNT',
	   Case
			When [Tax Amount] = 0 Then NULL
			Else [Sales Tax Group]
	   End as 'TAX CODE1',
	   Case
			When [Tax Amount] <> 0 Then NULL
			Else convert(Decimal(19,2),[Debit Amount] * @ExchangeRate)
	   End as 'NON TAXABLE AMOUNT',
	   Case
			When [Tax Amount] <> 0 Then NULL
			Else [Sales Tax Group]
	   End as 'TAX CODE2'
into #TempGSTReport
from #TempMSDynamicsRevenuePostPaid

Declare	@LocalPartnerCountry varchar(60)

select @LocalPartnerCountry = ConfigValue
from Referenceserver.UC_Admin.dbo.tb_Config
where ConfigName = 'LocalPartnerCountry' 
and AccessScopeID = -4

insert into #TempGSTReport
select substring(convert(varchar(10) , tbl1.PostingDate , 103) , 1,6) +
	   substring(convert(varchar(10) , tbl1.PostingDate , 103) , 9,2),
       --as 'INVOICE DATE',
	   tbl1.StatementNumber ,-- as 'INVOICE NO',
	   tbl2.Assignment + '-PREPAID-' + replace(@Documentdate , '/' , '') , --as 'DESCRIPTION OF TRANSACTION',
	   tbl1.Amount , --as 'INVOICE AMOUNT IN DOC CURRENCY',
	   tbl5.Currency , --as 'DOC CURRENCY',
	   Case
			When tbl4.Country = @LocalPartnerCountry Then convert(Decimal(19,2) ,tbl1.Amount * tbl1.ExchangeRate)
			Else convert(Decimal(19,2) ,tbl1.Amount * @ExchangeRate)
	   End , --as 'INVOICE AMOUNT LOCAL CURRENCY (SGD)',
	   NULL , --as 'TOTAL TAXABLE AMOUNT',
	   NULL , --as 'TAX AMOUNT',
	   NULL, -- as 'TAX CODE',
	   Case
			When tbl4.Country = @LocalPartnerCountry Then convert(Decimal(19,2) ,tbl1.Amount * tbl1.ExchangeRate)
			Else convert(Decimal(19,2) ,tbl1.Amount * @ExchangeRate)
	   End , --as 'NON TAXABLE AMOUNT',
	   'ZR'  --as 'TAX CODE'
from ReferenceServer.UC_Reference.dbo.tb_AccountReceivable tbl1
inner join tb_BillingAccountInfo tbl2 on tbl1.AccountID = tbl2.AccountID
inner join ReferenceServer.UC_Reference.dbo.tb_Account tbl3 on tbl1.AccountID = tbl3.AccountID
inner join ReferenceServer.UC_Reference.dbo.tb_Country tbl4 on tbl3.CountryID = tbl4.CountryID
inner join ReferenceServer.UC_Reference.dbo.tb_Currency tbl5 on tbl1.CurrencyID = tbl5.CurrencyID
where tbl1.AccountReceivableTypeID = -1 -- Advance Payments
and tbl1.PostingDate between @StartDate and @EndDate

select * from #TempGSTReport

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempTrafficDetail') )	
	Drop table #TempTrafficDetail

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempMSDynamicsRevenuePostPaid') )	
	Drop table #TempMSDynamicsRevenuePostPaid

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempMSDynamicsRevenuePrePaid') )	
	Drop table #TempMSDynamicsRevenuePrePaid

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempMSDynamicsExpensePostPaid') )	
	Drop table #TempMSDynamicsExpensePostPaid

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempMSDynamicsExpensePrePaid') )	
	Drop table #TempMSDynamicsExpensePrePaid

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempGSTReport') )	
	Drop table #TempGSTReport
GO
