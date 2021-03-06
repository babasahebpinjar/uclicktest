USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[temp_MSDynamicsAndTrafficDetail]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[temp_MSDynamicsAndTrafficDetail] as

Declare @Documentdate varchar(10) = '31/07/18'

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempBillingData') )	
	Drop table #TempBillingData

create table #TempBillingData
(
	Product	varchar(100),
	INRouteclass varchar(100),
	Destination	varchar(100),
	Country	varchar(100),
	Account	varchar(100),
	CarrierCountry varchar(50),
	Minutes	Decimal(19,2),
	Currency_USD Decimal(19,2),
	Currency_SGD Decimal(19,2),
	Rate Decimal(19,4),
	StatementNumber	varchar(100),
	StatementStatus	varchar(100),
	Direction varchar(50)
)

insert into #TempBillingData
select 'HUB REV' as Product,
       'Wholesale' as INRouteclass,
	   tbl1.Destination,
	   tbl1.Country,
	   tbl2.Assignment as Account,
	   tbl2.Country as CarrierCountry,
	    convert(decimal(19,2),sum(convert(decimal(19,2),CalldurationMinutes))) as Minutes,
		convert(decimal(19,2),sum(convert(decimal(19,2),ISNull(INAmount ,0)))) as Currency_USD,
		0 as Currency_SGD,
		 convert(decimal(19,4), convert(decimal(19,4),sum(ISNull(INAmount ,0)))/convert(decimal(19,4),sum(CalldurationMinutes))) as Rate,
		 Case
				When sum(ISNull(INAmount ,0)) = 0 then 'Not Applicable'
				Else isnull(tbl2.RevenueStatement, 'Not Applicable')
		 End as statementNumber,
		 Case
				When sum(ISNull(INAmount ,0)) = 0 then 'Not Applicable'
				Else 'Statement Issued'
		 End as Statementstatus,
		'Inbound' as Direction
from tb_CDRFileDataAnalyzed tbl1
left join tb_BillingAccountinfo tbl2 on tbl1.INAccount = tbl2.Account
where tbl1.country <> 'Singapore'
group by tbl1.Destination, tbl1.Country, tbl2.Assignment, tbl2.Country,
isnull(tbl2.RevenueStatement, 'Not Applicable')
having sum(CalldurationMinutes) > 0
order by tbl2.Assignment , tbl1.Destination


insert into #TempBillingData
select 'HUB EXP' as Product,
       'Wholesale' as INRouteclass,
	   tbl1.Destination,
	   tbl1.Country,
	   tbl2.Assignment as Account,
	   tbl2.Country as CarrierCountry,
	    convert(decimal(19,2),sum(convert(decimal(19,2),CalldurationMinutes))) as Minutes,
		convert(decimal(19,2),sum(convert(decimal(19,2),ISNull(OUTAmount ,0)))) as Currency_USD,
		0 as Currency_SGD,
		 convert(decimal(19,4), convert(decimal(19,4),sum(ISNull(OUTAmount ,0)))/convert(decimal(19,4),sum(CalldurationMinutes))) as Rate,
		 Case
				When sum(ISNull(OutAmount ,0)) = 0 then 'Not Applicable'
				Else isnull(tbl2.CostStatement, 'Not Applicable')
		 End as statementNumber,
		 Case
				When sum(ISNull(OutAmount ,0)) = 0 then 'Not Applicable'
				Else 'Statement Issued'
		 End as Statementstatus,
		'Outbound' as Direction
from tb_CDRFileDataAnalyzed tbl1
left join tb_BillingAccountinfo tbl2 on tbl1.OUTAccount = tbl2.Account
where tbl1.country <> 'Singapore'
group by tbl1.Destination, tbl1.Country, tbl2.Assignment, tbl2.Country, isnull(tbl2.CostStatement, 'Not Applicable')
having sum(CalldurationMinutes) > 0
order by tbl2.Assignment , tbl1.Destination


select * from #TempBillingData
--------------------------------------------------
-- Build the MS dynamics data for interface file
--------------------------------------------------

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
	   '61010104' as 'Offset account',
	   'B18000' as 'Offset account – BudgetCentre',
	   'ISVH' as 'Offset account – Product',
	   'P22100' as 'Offset account – Cost center',
	   'SG-001' as 'Offset account – Project',
	   'NON-SBO(I)' as 'Offset Account - SG_BOI'
from #TempBillingData tbl1
inner join tb_BillingAccountInfo tbl2 on tbl1.Account = tbl2.Assignment
where statementNumber <> 'Not Applicable'
and Direction = 'Inbound'
group by tbl2.CustomerCode, tbl1.StatementNumber,
		tbl1.Account + '-' + tbl1.Product + '-' + replace(@Documentdate , '/' , '')

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
	   'ZP' as 'Sales tax group',
	   'All' as 'Item Sales tax group',
	   0 as 'Tax Amount',
	   '' as 'Debit Amount',
	   sum(Currency_USD) as 'Credit Amount',
	   'Ledger' as 'Offset account type',
	   '71010103' as 'Offset account',
	   'B18000' as 'Offset account – BudgetCentre',
	   'ISVH' as 'Offset account – Product',
	   'P22100' as 'Offset account – Cost center',
	   'SG-001' as 'Offset account – Project',
	   'NON-SBO(I)' as 'Offset Account - SG_BOI'
from #TempBillingData tbl1
inner join tb_BillingAccountInfo tbl2 on tbl1.Account = tbl2.Assignment
where statementNumber <> 'Not Applicable'
and Direction = 'Outbound'
group by tbl2.VendorCode, tbl1.StatementNumber,
		tbl1.Account + '-' + tbl1.Product + ' ACC' +'-' + replace(@Documentdate , '/' , '')


if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempBillingData') )	
	Drop table #TempBillingData
GO
