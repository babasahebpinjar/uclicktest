USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetPrepaidBalanceDetailsByPeriod]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Procedure [dbo].[SP_UIGetPrepaidBalanceDetailsByPeriod]
(
	@AccountID int
)
As

--------------------------------------------------------------
-- Create Temp table to hold all the Prepaid Balance Details
--------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAccountPrepaidDetails') )
		Drop table #TempAccountPrepaidDetails

Create Table #TempAccountPrepaidDetails
(
	Period int,
	AccountReceivable Decimal(19,2),
	UsageAmount Decimal(19,2),
	NetClosingCreditBalance Decimal(19,2)
)

-----------------------------------------------------------
-- Insert into the temp table, records for all the periods
-- where the account is Prepaid
-----------------------------------------------------------

insert into #TempAccountPrepaidDetails
select Period, 0 ,0 ,0
from tb_AccountMode
where AccountID = @AccountID
and AccountmodeTypeID = -2-- Prepaid
and Period <= convert(int ,replace(convert(varchar(7) , getdate(), 120), '-' , ''));

----------------------------------------------
-- Update Account Receivables for each Period
----------------------------------------------
With CTE_AccountReceivables As
(
	select replace(convert(varchar(7) , PostingDate, 120), '-' , '') as Period,
		   convert(Decimal(19,2),sum(Amount)) as Amount
	from tb_AccountReceivable
	where AccountID = @AccountID
	Group by replace(Convert(varchar(7) , PostingDate, 120), '-' , '')
)
update tbl1
set AccountReceivable = tbl2.Amount
from #TempAccountPrepaidDetails tbl1
inner join CTE_AccountReceivables tbl2 on tbl1.Period = tbl2.Period

------------------------------------------------------------------------
-- Update Usage Amount for each Period based on Past and Current Balance
------------------------------------------------------------------------

Declare @CurrPeriod int 
Declare @CurrRunDate date =  dateadd(mm , -1 ,convert(date ,substring(convert(varchar(10) , getdate(),120) , 1,7) + '-' + '01'))
set @CurrPeriod = convert(int,replace(convert(varchar(7) , @CurrRunDate , 120), '-' , ''));

With CTE_PrepaidCurrentBalance As
(
	select convert(int,replace(convert(varchar(7) , CallDate, 120), '-' , '')) as Period,
		   convert(Decimal(19,2),sum(Amount)) as Amount
	from ReportServer.UC_Report.dbo.tb_PrepaidCurrentBalance
	where AccountID = @AccountID
	and convert(int,replace(convert(varchar(7) , CallDate , 120), '-' , '')) >= @CurrPeriod
	Group by convert(int,replace(convert(varchar(7) , CallDate, 120), '-' , ''))
)
update tbl1
set UsageAmount = tbl2.Amount
from #TempAccountPrepaidDetails tbl1
inner join CTE_PrepaidCurrentBalance tbl2 on tbl1.Period = tbl2.Period

update tbl1
set UsageAmount = tbl2.Amount
from #TempAccountPrepaidDetails tbl1
inner join ReportServer.UC_Report.dbo.tb_PrepaidPastBalance tbl2 on tbl1.Period = tbl2.Period
where tbl2.Period < @CurrPeriod


-------------------------------------------------------
-- Calculate the Net Closing Balance for Each Period
-------------------------------------------------------
update tbl1
set NetClosingCreditBalance = 
      ( select sum(AccountREceivable) - sum(Usageamount)
	    from #TempAccountPrepaidDetails tbl2
		where tbl2.PEriod <= tbl1.Period) -- Cumulative Total
from #TempAccountPrepaidDetails tbl1

select Period,
       Case
			When convert(int ,substring(convert(varchar(6) , Period) ,5,2)) = 1 then 'Jan'
			When convert(int ,substring(convert(varchar(6) , Period) ,5,2)) = 2 then 'Feb'
			When convert(int ,substring(convert(varchar(6) , Period) ,5,2)) = 3 then 'Mar'
			When convert(int ,substring(convert(varchar(6) , Period) ,5,2)) = 4 then 'Apr'
			When convert(int ,substring(convert(varchar(6) , Period) ,5,2)) = 5 then 'May'
			When convert(int ,substring(convert(varchar(6) , Period) ,5,2)) = 6 then 'Jun'
			When convert(int ,substring(convert(varchar(6) , Period) ,5,2)) = 7 then 'Jul'
			When convert(int ,substring(convert(varchar(6) , Period) ,5,2)) = 8 then 'Aug'
			When convert(int ,substring(convert(varchar(6) , Period) ,5,2)) = 9 then 'Sep'
			When convert(int ,substring(convert(varchar(6) , Period) ,5,2)) = 10 then 'Oct'
			When convert(int ,substring(convert(varchar(6) , Period) ,5,2)) = 11 then 'Nov'
			When convert(int ,substring(convert(varchar(6) , Period) ,5,2)) = 12 then 'Dec'
	   End + ' ' +substring(convert(varchar(6) , Period), 1,4) as PeriodName,
	   AccountReceivable,
	   UsageAmount,
	   NetClosingCreditBalance
from #TempAccountPrepaidDetails

ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAccountPrepaidDetails') )
		Drop table #TempAccountPrepaidDetails

GO
