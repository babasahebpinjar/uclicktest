USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIPublishUtilizationReport]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIPublishUtilizationReport]
(
	@AccountID int,
	@EndDate date,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @StartDate date

--set @AccountID = 2290		
--set @AccountID = 2257
--set @AccountID = 2243
--set @EndDate = '2019-11-30'

set @ErrorDescription = NULL
set @ResultFlag = 0

----------------------------------------------------------------
-- Dates need to be within the same year of the current End Date
----------------------------------------------------------------

set @StartDate = convert(date ,convert(varchar(4) , year(@EndDate)) + '-' + '01' + '-' + '01')

-- Debug Start
-- Select @StartDate as StartDate , @EndDate as EndDate
-- Debug End

					---------------------------------------------------------------------------------------------
					-- ******************************GET ESSENTIAL PARAMETERS ******************************
					---------------------------------------------------------------------------------------------

----------------------------------
-- ***** StatementXMLPath *****
----------------------------------

--------------------------------------------------------------------------
-- Get the location where all the physical account receivable invoices
-- are created
--------------------------------------------------------------------------

Declare @StatementXMLPath varchar(500)

select @StatementXMLPath = ConfigValue
from ReferenceServer.UC_Admin.dbo.tb_Config
where Configname = 'StatementXMLPath'
and AccessScopeID = -10

-- Debug Start
-- select @StatementXMLPath
-- Debug End

----------------------------------------------
-- Throw Error, if the path is not configured
----------------------------------------------
if (@StatementXMLPath is NULL)
Begin

	set @ErrorDescription = 'ERROR !!! Folder for generating utilization XML (StatementXMLPath) is not configured'
	set @ResultFlag = 1
	GOTO ENDPROCESS

End

-------------------------------------------------------------
-- Check to ensure that the folder is a valid accessible path
-------------------------------------------------------------

Declare @cmd varchar(2000)

if ( RIGHT(@StatementXMLPath , 1) <> '\' )
     set @StatementXMLPath = @StatementXMLPath + '\'

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempCommandoutput') )
	Drop table #tempCommandoutput

create table #tempCommandoutput
(
  CommandOutput varchar(500)
)

set @cmd = 'dir ' + '"' + @StatementXMLPath + '"' + '/b'
--print @cmd

insert into #tempCommandoutput
	Exec master..xp_cmdshell @cmd


if exists ( 
		select 1 from #tempCommandoutput
		where CommandOutput in (
					 'The system cannot find the file specified.',
					 'The system cannot find the path specified.',
					 'The network path was not found.',
					 'Access is denied.',
					 'File Not Found'
				       )								
          )		
Begin  

    set @ErrorDescription = 'Error !!! Accessing the Folder path : (' + @StatementXMLPath + '). This folder is essential for generating utilization xml'
	set @ResultFlag = 1
	GOTO ENDPROCESS

End


----------------------------------
-- ***** PDFInvoicePath *****
----------------------------------

--------------------------------------------------------------------------
-- Get the location where all the utilization PDF reports are created
--------------------------------------------------------------------------

Declare @PDFInvoicePath varchar(500)

select @PDFInvoicePath = ConfigValue
from ReferenceServer.UC_Admin.dbo.tb_Config
where Configname = 'PDFInvoicePath'
and AccessScopeID = -10

-- Debug Start
-- select @PDFInvoicePath
-- Debug End

----------------------------------------------
-- Throw Error, if the path is not configured
----------------------------------------------
if (@PDFInvoicePath is NULL)
Begin

	set @ErrorDescription = 'ERROR !!! Folder for generating utilization PDF (PDFInvoicePath) is not configured'
	set @ResultFlag = 1
	GOTO ENDPROCESS

End

-------------------------------------------------------------
-- Check to ensure that the folder is a valid accessible path
-------------------------------------------------------------

if ( RIGHT(@PDFInvoicePath , 1) <> '\' )
     set @PDFInvoicePath = @PDFInvoicePath + '\'


Delete from  #tempCommandoutput


set @cmd = 'dir ' + '"' + @PDFInvoicePath + '"' + '/b'
--print @cmd

insert into #tempCommandoutput
	Exec master..xp_cmdshell @cmd


if exists ( 
		select 1 from #tempCommandoutput
		where CommandOutput in (
					 'The system cannot find the file specified.',
					 'The system cannot find the path specified.',
					 'The network path was not found.',
					 'Access is denied.',
					 'File Not Found'
				       )								
          )		
Begin  

    set @ErrorDescription = 'Error !!! Accessing the Folder path : (' + @PDFInvoicePath + '). This folder is essential for generating utilization pdf'
	set @ResultFlag = 1
	GOTO ENDPROCESS

End

-----------------------------------------------------
-- ***** ConvertAccountReceivableXMLToPDFScript *****
-----------------------------------------------------

------------------------------------------------------------------------
-- Check if the utilization report generation Executable exists or not
------------------------------------------------------------------------
Declare @InvoiceGenerateExecutable varchar(500)

select @InvoiceGenerateExecutable = ConfigValue
from ReferenceServer.UC_Admin.dbo.tb_Config
where Configname = 'ConvertAccountReceivableXMLToPDFScript'
and AccessScopeID = -4

------------------------------------------------------
-- Throw an exception if the configuration os NULL
------------------------------------------------------

if (@InvoiceGenerateExecutable is NULL)
Begin

	set @ErrorDescription = 'Error !!! Configuration for executable to generate utilizatio pdf missing (ConvertAccountReceivableXMLToPDFScript)'
	set @ResultFlag = 1
	GOTO ENDPROCESS	

End

--------------------------------------------------------------------------------------
-- Check if the executable file exists in the location specified in the configuration
--------------------------------------------------------------------------------------
Declare @FileExists int

set @FileExists = 0

Exec master..xp_fileexist  @InvoiceGenerateExecutable , @FileExists output 

if ( @FileExists <> 1 )
Begin

	set @ErrorDescription = 'Error !!! Executable to generate utilization for prepaid accounts : (' + @InvoiceGenerateExecutable + ') does not exist or unaccessible.'
	set @ResultFlag = 1
	GOTO ENDPROCESS	

End

-----------------------------------------------
-- ***** Local or International Partner *****
-----------------------------------------------

----------------------------------------------------------------
-- Check if this is a local or international partner and get the
-- Exchange rates from the Forex schema
----------------------------------------------------------------
Declare @LocalPartner int = 0, -- Default to International Partner,
		@LocalPartnerCountry varchar(60)

select @LocalPartnerCountry = ConfigValue
from Referenceserver.UC_Admin.dbo.tb_Config
where ConfigName = 'LocalPartnerCountry' 
and AccessScopeID = -4

if (@LocalPartnerCountry is NULL)
Begin

	set @ErrorDescription = 'Error !!! Configuration for Local Country (LocalPartnerCountry) missing'
	set @ResultFlag = 1
	GOTO ENDPROCESS	

End

select @LocalPartner = 
	Case
		When isnull(tbl2.Country , 'Not Available') = @LocalPartnerCountry then 1
		Else 0
	End
from ReferenceServer.UC_Reference.dbo.tb_account tbl1
inner join ReferenceServer.UC_Reference.dbo.tb_Country tbl2 on tbl1.CountryID = tbl2.CountryID
where tbl1.AccountID = @AccountID


-----------------------------------------
-- ***** XML and PDF File Names  *****
-----------------------------------------

-----------------------------------------------------------
-- Get the Assignment from Billing Account Info to use in
-- the invoice file name
-----------------------------------------------------------
Declare @Filename varchar(500),
		@AccountAbbrv varchar(50)

select @AccountAbbrv = Assignment
from tb_BillingAccountInfo
where AccountID = @AccountID

if (@AccountAbbrv is NULL)
Begin

	set @ErrorDescription = 'Error !!! Billing Account Info for External Financial system missing'
	set @ResultFlag = 1
	GOTO ENDPROCESS	

End

set @Filename = @AccountAbbrv + '_'+ 
Case Month(@EndDate)
	When 1 then 'Jan'
	When 2 then 'Feb'
	When 3 then 'Mar'
	When 4 then 'Apr'
	When 5 then 'May'
	When 6 then 'Jun'
	When 7 then 'Jul'
	When 8 then 'Aug'
	When 9 then 'Sep'
	When 10 then 'Oct'
	When 11 then 'Nov'
	When 12 then 'Dec'											
End + convert(varchar(4) , YEAR(@EndDate)) + '_' + 'Utilisation'


-----------------------------------------------------------------
-- Build the complete name of the file that needs to be generated
-----------------------------------------------------------------
Declare @CompleteFileName varchar(500),
        @FinalInvoice varchar(500)


set @CompleteFileName = @StatementXMLPath + @Filename + '.xml'
set @FinalInvoice = @PDFInvoicePath + @Filename + '.pdf'

-- Debug Start
-- select @CompleteFileName , @FinalInvoice
-- Debug End


					---------------------------------------------------------------------------------------------
					-- ****************************** UTILIZATION SUMMARY SECTION ******************************
					---------------------------------------------------------------------------------------------


------------------------------------------------------------
-- Create schema to store the exchange rate for USD to SGD
------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempExchangeRate') )
		Drop table #tempExchangeRate

	Select ExchangeRate ,BeginDate , Convert(datetime ,NULL) as EndDate
	into #tempExchangeRate 
	from REFERENCESERVER.UC_Reference.dbo.tb_Exchange
	where CurrencyID = 1014
	order by BeginDate

Update tbl1 
Set  EndDate = (
					Select Min(BeginDate)  - 1
					From   #tempExchangeRate tbl2 
					Where  tbl1.BeginDate < tbl2.BeginDate
				) 
FROM #tempExchangeRate tbl1;

-- Debug Start
-- select * from #tempExchangeRate;
-- Debug End

----------------------------------------------------------------------------
-- Create a temp table to store all the Traffic Summary by Period for 
-- the year
----------------------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempTrafficSummary') )
		Drop table #tempTrafficSummary;

Create Table #tempTrafficSummary
(
	Amount Decimal(19,2),
	CallDurationMinutes  Decimal(19,2),
	LastPeriodDate date,
	PeriodNum int,
	InvoiceDesc varchar(500)
);

with CTE_Traffic_All_Periods As
(
		select tbl1.AccountID, 
			   tbl3.AccountAbbrv ,
			   tbl1.SettlementDestinationID,
			   tbl4.Destination,
			   convert(Decimal(19,2) ,sum(convert(decimal(19,4) ,RoundedCallDuration/60.0))) as Minutes,
			   convert(Decimal(19,2),sum(Amount)) as Amount,
			   Case
					When month(tbl1.CallDate) = 1 then 'January'
					When month(tbl1.CallDate) = 2 then 'February'
					When month(tbl1.CallDate) = 3 then 'March'
					When month(tbl1.CallDate) = 4 then 'April'
					When month(tbl1.CallDate) = 5 then 'May'
					When month(tbl1.CallDate) = 6 then 'June'
					When month(tbl1.CallDate) = 7 then 'July'
					When month(tbl1.CallDate) = 8 then 'August'
					When month(tbl1.CallDate) = 9 then 'September'
					When month(tbl1.CallDate) = 10 then 'October'
					When month(tbl1.CallDate) = 11 then 'November'
					When month(tbl1.CallDate) = 12 then 'December'
			   End  + ' ' + convert(varchar(4) , year(tbl1.CallDate)) + ' Traffic' as CallPeriod ,
			   convert(int ,convert(varchar(4) , year(tbl1.CallDate)) + right('0' + convert(varchar(2) , month(tbl1.CallDate)) ,2)) as CallPeriodNum
		from tb_DailyINUnionOutFinancial tbl1
		inner join ReferenceServer.UC_Reference.dbo.tb_account tbl3 on tbl1.AccountID = tbl3.AccountID
		inner join ReferenceServer.UC_Reference.dbo.tb_Destination tbl4 on tbl1.SettlementDestinationID = tbl4.DestinationID
		where ErrorIndicator = 0
		and DirectionID = 1
		and CallDuration > 0
		and calldate between @StartDate and @EndDate
		and tbl1.AccountID = @AccountID
		group by tbl1.AccountID, tbl3.AccountAbbrv ,
				 tbl1.SettlementDestinationID, tbl4.Destination,
				 Case
					When month(tbl1.CallDate) = 1 then 'January'
					When month(tbl1.CallDate) = 2 then 'February'
					When month(tbl1.CallDate) = 3 then 'March'
					When month(tbl1.CallDate) = 4 then 'April'
					When month(tbl1.CallDate) = 5 then 'May'
					When month(tbl1.CallDate) = 6 then 'June'
					When month(tbl1.CallDate) = 7 then 'July'
					When month(tbl1.CallDate) = 8 then 'August'
					When month(tbl1.CallDate) = 9 then 'September'
					When month(tbl1.CallDate) = 10 then 'October'
					When month(tbl1.CallDate) = 11 then 'November'
					When month(tbl1.CallDate) = 12 then 'December'
			   End  + ' ' + convert(varchar(4) , year(tbl1.CallDate)) + ' Traffic',
			  convert(int ,convert(varchar(4) , year(tbl1.CallDate)) + right('0' + convert(varchar(2) , month(tbl1.CallDate)) ,2))
)	
insert into #tempTrafficSummary																																																		
select convert(decimal(19,2) ,sum(Amount)), --as Amount
	   convert(decimal(19,2) , sum(Minutes)), --as CallDurationMinutes
	   dateadd(dd , -1 , dateadd(mm ,1 , convert(date , convert(varchar(6) ,CallPeriodNum) + '01'))), --as LastPeriodDate
	   CallPeriodNum, -- as PeriodNum
	   CallPeriod -- as InvoiceDesc
--into #tempTrafficSummary
from CTE_Traffic_All_Periods
group by CallPeriod,CallPeriodNum
order by CallPeriodNum

--------------------------------------------------------------
-- Delete all the entries for period, where the account is not
-- Pr-epaid
--------------------------------------------------------------
Delete tbl1
from #tempTrafficSummary tbl1
inner join ReferenceServer.UC_Reference.dbo.tb_AccountMode tbl2
		on tbl2.AccountID = @AccountID and tbl1.PeriodNum = tbl2.Period
where tbl2.AccountModeTypeID <> -2 -- Not Prepaid

---------------------------------------------------------
-- Based on whether it is a local or international partner
-- update the Exchange rate
---------------------------------------------------------

-- Add a Exchange Rate column to the Traffic Summary Temp Table
Alter Table #tempTrafficSummary add ExchangeRate Decimal(19,4)
Alter Table #tempTrafficSummary add RecordType varchar(100)

if (@LocalPartner = 1)
Begin

	update tbl1
	set ExchangeRate = tbl2.ExchangeRate,
	    RecordType = 'Traffic'
	from #tempTrafficSummary tbl1
	inner join #tempExchangeRate tbl2 on tbl1.LastPeriodDate between tbl2.BeginDate and isnull(tbl2.EndDate , tbl1.LastPeriodDate)

End

else
Begin

	update #tempTrafficSummary
	set ExchangeRate = 1, -- If its not a local partner then set the exchange rate as 1
	    RecordType = 'Traffic'

End

-- Debug Start
-- select * from #tempTrafficSummary
-- Debug End

--------------------------------------------------------------------
-- Get all the advance payments that have been received in the year
--------------------------------------------------------------------

----------------------------------------------------------------
-- Create a temp table to store all the Account Receivables
----------------------------------------------------------------
if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempAccountReceivable') )
		Drop table #tempAccountReceivable

select *
into #tempAccountReceivable
from #tempTrafficSummary
where 1 = 2

insert into #tempAccountReceivable
select Amount , 0 , PostingDate,
	   convert(int ,convert(varchar(4) , year(PostingDate)) + right('0' + convert(varchar(2) , month(PostingDate)) ,2)),
	   Case
			When AccountReceivabletypeID = -1 then 'Advance Payment'
			When AccountReceivabletypeID = -2 then 'Forfeit of Advance Payment'
			When AccountReceivabletypeID = -3 then 'Refund'
			When AccountReceivabletypeID = -4 then 'Adjustment'
			When AccountReceivabletypeID = -5 then 'Writeoff'
	   End
	   'Advance Payment',
	   ExchangeRate,
	   Case
			When AccountReceivabletypeID = -1 then 'Payment'
			When AccountReceivabletypeID = -2 then 'Forfeit'
			When AccountReceivabletypeID = -3 then 'Refund'
			When AccountReceivabletypeID = -4 then 'Adjustment'
			When AccountReceivabletypeID = -5 then 'Writeoff'
	   End
from Referenceserver.UC_Reference.dbo.tb_Accountreceivable tbl1
where AccountID = @AccountID
and convert(int ,convert(varchar(4) , year(PostingDate)) + right('0' + convert(varchar(2) , month(PostingDate)) ,2)) between
	convert(int ,convert(varchar(4) , year(@StartDate)) + right('0' + convert(varchar(2) , month(@StartDate)) ,2))
	and
	convert(int ,convert(varchar(4) , year(@EndDate)) + right('0' + convert(varchar(2) , month(@EndDate)) ,2))


-- Debug Start
-- select * from #tempAccountReceivable
-- Debug End

------------------------------------------------------------------
-- Build the final utilization summary table with all the records
------------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempUtilizationFinal') )
		Drop table #tempUtilizationFinal

select *
into #tempUtilizationFinal
from #tempTrafficSummary
where 1 = 2

insert into #tempUtilizationFinal
select * from
(
	select * from #tempTrafficSummary
	union
	select * from #tempAccountReceivable
) tbl1
order by PeriodNum , LastPeriodDate

--------------------------------------------------------------
-- Except for Payment Record Type make the amount negative
-- for all other records
-- Also add the amount in SGD after applying the exchange rate
--------------------------------------------------------------
Alter table #tempUtilizationFinal Add AmountInLocal Decimal(19,2)

update #tempUtilizationFinal
set Amount = 
		Case
			When RecordType = 'Traffic' Then Amount * -1.00
			Else Amount
		End ,
	AmountInLocal = 
		Case
			When RecordType = 'Traffic' Then convert(Decimal(19,2) ,Amount * ExchangeRate * -1.00)
			Else  convert(Decimal(19,2) ,Amount * ExchangeRate)
		End

-- Debug Start
-- select * from #tempUtilizationFinal
-- Debug End

					---------------------------------------------------------------------------------------------
					-- ****************************** DETAIL USAGE SECTION ************************************
					---------------------------------------------------------------------------------------------

--------------------------------------------------
-- Set the Start Date to the Start of the Month
--------------------------------------------------

Declare @AccountModeTypeID int

select @AccountModeTypeID = AccountModeTypeID
from Referenceserver.UC_Reference.dbo.tb_AccountMode
where AccountID = @AccountID
and Period = convert(int ,convert(varchar(4) , year(@EndDate)) + right('0' + convert(varchar(2) , month(@EndDate)) ,2))

set @StartDate = convert(date ,convert(varchar(4) , year(@EndDate)) + '-' + right('0' + convert(varchar(2) , month(@EndDate)) ,2) + '-' + '01')

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempMonthlyFinancial') )
		Drop table #TempMonthlyFinancial

select tbl1.AccountID, 
		tbl3.AccountAbbrv ,
		tbl2.RevenueStatement, 
		tbl1.SettlementDestinationID,
		tbl4.Destination,
		convert(Decimal(19,4) ,Rate) as Rate,
		Min(CallDate) as MinDate,
		Max(CallDate) as MaxDate,
		sum(Answered) as TotalCalls,
		convert(Decimal(19,2) ,sum(convert(decimal(19,4) ,RoundedCallDuration/60.0))) as Minutes,
		convert(Decimal(19,2),sum(Amount)) as Amount	   
into #TempMonthlyFinancial
from tb_DailyINUnionOutFinancial tbl1
inner join tb_BillingAccountInfo tbl2 on tbl1.AccountID = tbl2.AccountID
inner join ReferenceServer.UC_Reference.dbo.tb_account tbl3 on tbl1.AccountID = tbl3.AccountID
inner join ReferenceServer.UC_Reference.dbo.tb_Destination tbl4 on tbl1.SettlementDestinationID = tbl4.DestinationID
where ErrorIndicator = 0
and DirectionID = 1
and CallDuration > 0
and calldate between @StartDate and @EndDate
and tbl1.AccountID = @AccountID
group by tbl1.AccountID, tbl3.AccountAbbrv ,tbl2.RevenueStatement,
			tbl1.SettlementDestinationID, tbl4.Destination, convert(Decimal(19,4) ,Rate)

--------------------------------------------------
-- Delete all usage records for the account incase
-- it is not Prepaid in the month
--------------------------------------------------

if (@AccountModeTypeID <> -2) -- Prepaid
Begin

	Delete from #TempMonthlyFinancial

End


-- Debug Start
-- select * from #TempMonthlyFinancial
-- Debug End


					---------------------------------------------------------------------------------------------
					-- ****************************** BUILD INVOICE XML ************************************
					---------------------------------------------------------------------------------------------

Declare @InvoicePeriod varchar(50),
	    @TaxInvoice varchar(100)


set @InvoicePeriod =
Case Month(@EndDate)
	When 1 then 'JANUARY'
	When 2 then 'FEBRUARY'
	When 3 then 'MARCH'
	When 4 then 'APRIL'
	When 5 then 'MAY'
	When 6 then 'JUNE'
	When 7 then 'JULY'
	When 8 then 'AUGUST'
	When 9 then 'SEPTEMBER'
	When 10 then 'OCTOBER'
	When 11 then 'NOVEMBER'
	When 12 then 'DECEMBER'											
End + ' ' + convert(varchar(4) , YEAR(@EndDate))


-----------------------------------------------------------------------------
-- When the traffic exists in the month , then we use the temp Traffic table
-- to get the invoice, else we get it from the Billing Account Info
-----------------------------------------------------------------------------

if ( (select count(*) from  #TempMonthlyFinancial) > 0 )
Begin

	Select @TaxInvoice = RevenueStatement
	from
	(
		Select top 1 *
		from #TempMonthlyFinancial
	) as TBL1

End

Else
Begin

	Select @TaxInvoice = RevenueStatement
	from tb_BillingAccountInfo
	where AccountID = @AccountID

End

------------------------------------------------
-- If there are no records in the utilization
-- table then it means that there is nothing to
-- publish for this account
 ------------------------------------------------
if ( (select count(*) from #tempUtilizationFinal) = 0 )
Begin

	set @ErrorDescription = 'Error !!! No utilization data related to Account Receivables or Traffic available for this account'
	set @ResultFlag = 1
	GOTO ENDPROCESS	

End
				

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempBillingAccountXMLData') )	
	Drop table #TempBillingAccountXMLData

Create table #TempBillingAccountXMLData
(
	RecordID int identity(1,1),
	RecordData varchar(2000)
)


insert into #TempBillingAccountXMLData (RecordData)
select '<?xml version="1.0" encoding="UTF-8"?>'

insert into #TempBillingAccountXMLData (RecordData)
select '<invoice statementdate="'+ replace(upper(convert(varchar(100) , @EndDate , 106)), ' ', '-') +'" '+ 
		'statementperiod="'+@InvoicePeriod +'" '+
		'statementno="' + @TaxInvoice + '" '+
		'filename="' + @Filename + '" ' +
		'modetype="utilization" ' +
		'statementyear="' + convert(varchar(4) , year(@EndDate)) + '" >'

insert into #TempBillingAccountXMLData (RecordData)
Select 
		Case
				When @LocalPartner = 0 then '<summary total-sg="" '
				Else '<summary total-sg="' + 
					Case
						When AmountInLocal < 0 then '(' +convert(varchar(100) ,convert(decimal(19,2) ,AmountInLocal * -1.00)) + ')" '
						Else convert(varchar(100) ,convert(decimal(19,2) ,AmountInLocal)) + '" '
					End
		End +
	   'total-us="' + 
			Case
				When Amount < 0 Then '(' + convert(varchar(100) ,convert(decimal(19,2) ,Amount * -1.00)) + ')" >'
				Else convert(varchar(100) ,convert(decimal(19,2) ,Amount)) + '" >'
			End
from
(
	select convert(decimal(19,2) ,sum(Amount)) as Amount,
		   convert(decimal(19,2) ,sum(AmountInLocal)) as AmountInLocal
	from #tempUtilizationFinal
) tbl1


insert into #TempBillingAccountXMLData (RecordData)
Select '<traffic date="'+ replace(convert(varchar(10) , LastPeriodDate , 105) , '-' , '/') + '" '+  
		'desc="' + InvoiceDesc + '" '+     
		Case
				When @LocalPartner = 0 then 'amount-sg="" '
				Else 'amount-sg="' + 
					Case
					   When AmountInLocal < 0 then '('+ convert(varchar(100) ,convert(decimal(19,2) ,AmountInLocal * -1.00)) + ')" ' 
					   Else convert(varchar(100) ,convert(decimal(19,2) ,AmountInLocal)) + '" '
					End
		End +	   
	   'amount-us="' + 
			Case
			    When Amount < 0 then '('+convert(varchar(100) ,convert(decimal(19,2) ,Amount * -1.00)) + ')" ' 
				Else convert(varchar(100) ,convert(decimal(19,2) ,Amount)) + '" '
			End +
	   'minutes="' + 
				Case 
					when CallDurationMinutes = 0 then ''
				    else convert(varchar(100) ,convert(decimal(19,2) ,CallDurationMinutes)) 
				End + '" />' 
from #tempUtilizationFinal
order by PeriodNum , LastPeriodDate


insert into #TempBillingAccountXMLData (RecordData)
select '</summary>'

if ( (select count(*) from #TempMonthlyFinancial) > 0 )
Begin

		insert into #TempBillingAccountXMLData (RecordData)
		select '<hubbingcharges '+
			   'trafficperiod="' + @InvoicePeriod + '" '+
			   'totalamount-us="' + convert(varchar(100) ,convert(decimal(19,2) ,Amount)) + '" '+
			   'totalminutes="' + convert(varchar(100) ,convert(decimal(19,2) ,CallDurationMinutes)) + '" ' +
			   'totalnoofcalls="' + convert(varchar(100) ,TotalCalls) + '">'
		from 
		(
			select convert(varchar(100),convert(decimal(19,2) ,sum(Amount))) as Amount,
				  convert(varchar(100),convert(decimal(19,2) , sum(Minutes))) as CallDurationMinutes,
				  sum(TotalCalls) as TotalCalls
			from #TempMonthlyFinancial
		) as tbl1

		insert into #TempBillingAccountXMLData (RecordData)
		select '<hubbingcharge ' +
			   'amount-us = "' + convert(varchar(100),convert(decimal(19,2) ,Amount)) + '"' +
			   ' minutes = "' + convert(varchar(100),convert(decimal(19,2) , Minutes)) + '"' +
			   ' rate = "' + convert(varchar(100) ,convert(decimal(19,4) ,Rate)) + '"' +
			   ' noofcalls= "'+
			   convert(varchar(100),TotalCalls) + '"' +
			   ' enddate="'+ convert(varchar(100) ,MaxDate, 106) + '"' +
			   ' startdate="' + convert(varchar(100),MinDate, 106)+ '"'+
			   ' dest="' + Destination + '"/>'
		from #TempMonthlyFinancial
		order by Destination

		insert into #TempBillingAccountXMLData (RecordData)
		select '</hubbingcharges>'

End

insert into #TempBillingAccountXMLData (RecordData)
select '<toaddress>'

insert into #TempBillingAccountXMLData (RecordData)
select '<name>'+ ContactName +  Case when right(ContactName,1) <> ',' then ',' else '' End + '</name>'
from tb_BillingAccountInfo
where AccountID = @AccountID

insert into #TempBillingAccountXMLData (RecordData)
select '<companyname>' + CompanyName +  Case when right(CompanyName,1) <> ',' then ',' else '' End +'</companyname>'
from tb_BillingAccountInfo
where AccountID = @AccountID

insert into #TempBillingAccountXMLData (RecordData)
select '<address1>'+ Address1 +  Case when (Address2 is not null) and right(Address1,1) <> ',' then ',' else '' End + '</address1>'
from tb_BillingAccountInfo
where AccountID = @AccountID

insert into #TempBillingAccountXMLData (RecordData)
select '<address2>'+ Address2 +  Case when (Address3 is not null) and right(Address2,1) <> ',' then ',' else '' End + '</address2>'
from tb_BillingAccountInfo
where AccountID = @AccountID

insert into #TempBillingAccountXMLData (RecordData)
select '<address3>'+ Address3 +  Case when (Address4 is not null) and right(Address3,1) <> ',' then ',' else '' End + '</address3>'
from tb_BillingAccountInfo
where AccountID = @AccountID

insert into #TempBillingAccountXMLData (RecordData)
select '<address4>'+ isnull(Address4,'') + '</address4>'
from tb_BillingAccountInfo
where AccountID = @AccountID

insert into #TempBillingAccountXMLData (RecordData)
select '<email>'+ EmailAddress + '</email>'
from tb_BillingAccountInfo
where AccountID = @AccountID

insert into #TempBillingAccountXMLData (RecordData)
select '</toaddress>'

insert into #TempBillingAccountXMLData (RecordData)
select '<otherinfo email="ABS_Finance_Operations@axiata.com" />' 

insert into #TempBillingAccountXMLData (RecordData)
select '</invoice>'

----------------------------------------------------------------
-- Mark all the special characters in XML to ensure it does not
-- fail in conversion
----------------------------------------------------------------
update #TempBillingAccountXMLData
set RecordData = replace(RecordData , '&' , '&#38;')


-- Debug Start
select * from #TempBillingAccountXMLData
-- Debug End


					---------------------------------------------------------------------------------------------
					-- ****************************** GENERATE XML FILE ************************************
					---------------------------------------------------------------------------------------------

-----------------------------------------------------------------
-- Delete the files if it already exists in the output directory
-----------------------------------------------------------------
--------
-- XML
--------
set @FileExists = 0

Exec master..xp_fileexist @CompleteFileName , @FileExists output 

if (@FileExists = 1)
Begin

		set @cmd = 'del '+ @CompleteFileName
		exec master..xp_cmdshell @cmd	

End


--------
-- PDF
--------
set @FileExists = 0

Exec master..xp_fileexist @FinalInvoice , @FileExists output 

if (@FileExists = 1)
Begin

		set @cmd = 'del '+ @FinalInvoice
		exec master..xp_cmdshell @cmd	

End

--------------------------------------------------------------------
-- Publish the XML file created into the advance payment directory
--------------------------------------------------------------------

-----------------------------------------
-- Output the desired results to file
-----------------------------------------

if exists ( select 1 from #TempBillingAccountXMLData)
Begin


        Declare	@RecordFile varchar(500),
				@datestring varchar(100),
			    @bcpCommand varchar(5000),
			    @res int,
			    @QualifiedTableName varchar(500)

		 -- Delete any pre-existing instance of the XML file

		 set @FileExists = 0

		Exec master..xp_fileexist  @CompleteFileName , @FileExists output 

		if ( @FileExists = 1 )
		Begin

		        set @bcpCommand = 'del '+ @CompleteFileName
				EXEC master..xp_cmdshell @bcpCommand 

		End

		 -- Create the file with all the records

		 set @QualifiedTableName = 'TempXML_'+ @Filename

		 if exists ( select 1 from sysobjects where name = @QualifiedTableName and xtype = 'U')
			Exec('Drop table ' + @QualifiedTableName)

         -- Move the data from the temporary table to the qualified table
		 Exec('select * into '+ @QualifiedTableName + ' from #TempBillingAccountXMLData')

         Set @QualifiedTableName = db_name() + '.dbo.' + @QualifiedTableName

         SET @bcpCommand = 'bcp "SELECT RecordData from ' + @QualifiedTableName + ' order by RecordID" queryout ' + '"' + ltrim(rtrim(@CompleteFileName )) + '"' + ' -c -r"\n" -T -S '+ @@servername
         --print @bcpCommand 

         EXEC master..xp_cmdshell @bcpCommand

		 set @QualifiedTableName = 'TempXML_'+ @Filename

		 if exists ( select 1 from sysobjects where name = @QualifiedTableName and xtype = 'U')
		 Exec('Drop table ' + @QualifiedTableName)

		 -- Check if the XML File exists or not

		 set @FileExists = 0

		 Exec master..xp_fileexist  @CompleteFileName , @FileExists output 

		 if ( @FileExists <> 1 )
		 Begin

			set @ErrorDescription = 'Error !!! XML File : (' + @CompleteFileName + ') not created for utilization report.'
			set @ResultFlag = 1
			GOTO ENDPROCESS	

		 End

End

Else
Begin

		set @ErrorDescription = 'Error !!! No utilization information found to build the invoice XML'
		set @ResultFlag = 1
		GOTO ENDPROCESS	

End

					---------------------------------------------------------------------------------------------
					-- ****************************** GENERATE PDF FILE ************************************
					---------------------------------------------------------------------------------------------

--------------------------------------------------------------------------
-- Buld the command prompt execution command to generate the PDF invoice
--------------------------------------------------------------------------

set @cmd = '""' + @InvoiceGenerateExecutable + '" ' +  -- Added double quotes twice at beginning and end as xp_cmdshell requires it when running the command
           '"' + @CompleteFileName + '" ' +
		   '"' + @PDFInvoicePath + '\""' -- Added this "\" due to limitation of the invoice generation executable

-- Debug Start
print @cmd
-- Debug End

----------------------------------------------------------------
-- Run the command using the XP_CMDSHELL to generate the invoice
----------------------------------------------------------------

Delete from #tempCommandoutput

insert into #tempCommandoutput
EXEC master..xp_cmdshell @cmd

-- Debug Start
select *
from #tempCommandoutput
-- Debug End

--------------------------------------------------------------------
-- Check if the invoice has been created and delete the xml file
--------------------------------------------------------------------
set @FileExists = 0

Exec master..xp_fileexist  @FinalInvoice , @FileExists output 

if ( @FileExists <> 1 )
Begin

		set @ErrorDescription = 'ERROR !!!! PDF Utilization File not created due to some exception'
		set @ResultFlag = 1

		---------------------------------------------
		-- Delete the XML file from the system
		---------------------------------------------

		set @bcpCommand = 'del '+ @CompleteFileName
		EXEC master..xp_cmdshell @bcpCommand 

		GOTO ENDPROCESS

End

else
Begin

		---------------------------------------------
		-- Delete the XML file from the system
		---------------------------------------------

		set @bcpCommand = 'del '+ @CompleteFileName
		EXEC master..xp_cmdshell @bcpCommand 


End



ENDPROCESS:

-- Debug Start
Select @ErrorDescription ErrorDescription , @ResultFlag ResultFlag
-- Debug End

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempExchangeRate') )
		Drop table #tempExchangeRate

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempTrafficSummary') )
		Drop table #tempTrafficSummary

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempAccountReceivable') )
		Drop table #tempAccountReceivable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempUtilizationFinal') )
		Drop table #tempUtilizationFinal

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempMonthlyFinancial') )
		Drop table #TempMonthlyFinancial

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempBillingAccountXMLData') )	
		Drop table #TempBillingAccountXMLData

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempCommandoutput') )
		Drop table #tempCommandoutput





GO
