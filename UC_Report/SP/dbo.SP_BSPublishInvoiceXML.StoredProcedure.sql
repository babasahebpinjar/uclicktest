USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSPublishInvoiceXML]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSPublishInvoiceXML]
As

Declare @StartDate Date,
        @EndDate Date,
		@AccountID int,
		@ExchangeRate Decimal(19,4),
		@GSTPercent decimal(19,2)


set @StartDate = '2019-10-01'
set @EndDate = '2019-10-31'
set @AccountID = 2244
set @ExchangeRate = 1.3603
set @GSTPercent = 0.00



Declare @InvoicePeriod varchar(50),
        @TaxInvoice varchar(100),
		@InvoiceDate datetime,
		@Filename varchar(500),
		@AccountAbbrv varchar(50),
		@InvoiceDueDate datetime,
		@MaxMonthEndDate date

Declare @FileExtractPath varchar(1000),
        @ExtractFileName  varchar(1000),
		@ErrorMsgStr varchar(2000) = NULL

set @MaxMonthEndDate =    DateAdd(dd , -1,
								  convert( date ,
										   convert(varchar(4) , Year(dateAdd(mm , 1 , @EndDate))) + '-' +
										   convert(varchar(2) , right('0' + month(dateAdd(mm , 1 , @EndDate)),2)) + '-' + '01'
										 )
								  )


--select @MaxMonthEndDate

-- Get the  Statement XML path from the config table

select @FileExtractPath = ConfigValue
from ReferenceServer.UC_Admin.dbo.tb_Config
where AccessScopeID = -10
and ConfigName = 'StatementXMLPath'

if ( @FileExtractPath is NULL )
Begin

		set @ErrorMsgStr = 'Error !!! Configuration for Stamement XML path not defined (StatementXMLPath)'
		Raiserror('%s' , 16 , 1, @ErrorMsgStr)
		GOTO ENDPROCESS	

End

if (right(@FileExtractPath , 1) <> '\')
	set @FileExtractPath = @FileExtractPath + '\'		

Select @AccountAbbrv =  AccountAbbrv
from ReferenceServer.UC_Reference.dbo.tb_Account
where accountID = @AccountID

if ( (@EndDate != @MaxMonthEndDate ) or (day(@StartDate) != 1))
Begin

	set @InvoicePeriod =
	convert(varchar(10) , day(@StartDate)) + '-' + convert(varchar(10) , day(@EndDate)) + ' ' +
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

End

Else
Begin

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

End
		
set @InvoiceDate = @EndDate
set @InvoiceDueDate = DateAdd(dd , 30,@InvoiceDate )


if ( (@EndDate != @MaxMonthEndDate ) or (day(@StartDate) != 1))
Begin

		set @Filename = @AccountAbbrv + '_'+ 'Inbound' + '_' +
		convert(varchar(10) , day(@StartDate)) + '-' + convert(varchar(10) , day(@EndDate)) + 
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
		End + convert(varchar(4) , YEAR(@EndDate)) + '_' + 'Invoice'

End

Else
Begin

		set @Filename = @AccountAbbrv + '_'+ 'Inbound' + '_' +
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
		End + convert(varchar(4) , YEAR(@EndDate)) + '_' + 'Invoice'

End

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

--select * from #TempMonthlyFinancial

Select @TaxInvoice = RevenueStatement
from
(
	Select top 1 *
	from #TempMonthlyFinancial
) as TBL1

------------------------------------------------------
-- Depending on the home country of the account decide
-- whether this is intenational or local partner
------------------------------------------------------
Declare @LocalPartner int  = 0 -- Defaul is to consider as international partner

select @LocalPartner = 
			Case
				When isnull(tbl2.Country, 'Not Available') = 'Singapore' then 1
				Else 0
			End
From ReferenceServer.UC_Reference.dbo.tb_Account tbl1
left join ReferenceServer.UC_Reference.dbo.tb_Country tbl2 on tbl1.CountryID = tbl2.CountryID
where tbl1.AccountID = @AccountID

--------------------------------------------------------
-- Create a temporary table to insert all the XML data
--------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempBillingAccountXMLData') )	
	Drop table #TempBillingAccountXMLData

Create table #TempBillingAccountXMLData
(
	RecordID int identity(1,1),
	RecordData varchar(2000)
)

insert into #TempBillingAccountXMLData (RecordData)
select '<?xml version="1.0" encoding="UTF-8"?>'

--select @InvoiceDueDate as InvoiceDueDate,
--       @InvoiceDate as InvoiceDate,
--	   @InvoicePeriod as InvoicePeriod,
--	   @TaxInvoice as TaxInvoice,
--	   @Filename as Filename

insert into #TempBillingAccountXMLData (RecordData)
select '<invoice duedate="'+ replace(upper(convert(varchar(100) , @InvoiceDueDate , 106)), ' ', '-') +'" '+ 
        'paymenterm="30 DAYS" ' +
		'invoicedate="'+ replace(upper(convert(varchar(100) , @InvoiceDate , 106)), ' ' ,'-') +'" '+ 
		'invoiceperiod="'+@InvoicePeriod +'" '+
		'taxinvoice="' + @TaxInvoice + '" '+
		'filename="' + @Filename + '" >'

insert into #TempBillingAccountXMLData (RecordData)
Select 
		Case
				When @LocalPartner = 0 then '<summary usdvalue="" '
				Else '<summary usdvalue="'+ convert(varchar(100), @ExchangeRate) + ' SGD' + '" '
		End +
		Case
				When @LocalPartner = 0 then 'total-sg="" '
				Else 'total-sg="' + convert(varchar(100) ,convert(decimal(19,2) ,Amount * @ExchangeRate * (1 + @GSTPercent))) + '" '
		End +
	   'total-us="' + convert(varchar(100) ,convert(decimal(19,2) ,Amount * (1 + @GSTPercent))) + '" '+
		Case
				When @LocalPartner = 0 then 'gst-sg="" '
				Else 'gst-sg="' + convert(varchar(100) ,convert(decimal(19,2) ,Amount * @ExchangeRate * @GSTPercent)) + '" '
		End +	   
	   'gst-us="' + convert(varchar(100) ,convert(decimal(19,2) ,Amount * @GSTPercent)) + '" '+
		Case
				When @LocalPartner = 0 then 'subtotal-sg="" '
				Else 'subtotal-sg="' + convert(varchar(100) ,convert(Decimal(19,2),Amount * @ExchangeRate)) + '" ' 
		End +	   
	   'subtotal-us="' + convert(varchar(100) ,Amount) + '" ' +
	   'gst-percent="' + convert(varchar(100) ,convert(int ,@GSTPercent*100)) + '">' 
from 
(
	select convert(varchar(100),convert(decimal(19,2) ,sum(Amount))) as Amount
	from #TempMonthlyFinancial
) as tbl1

insert into #TempBillingAccountXMLData (RecordData)
Select '<traffic '+
		Case
				When @LocalPartner = 0 then 'amount-sg="" '
				Else 'amount-sg="' + convert(varchar(100) ,convert(decimal(19,2) ,Amount * @ExchangeRate)) + '" ' 
		End +	   
	   'amount-us="' + convert(varchar(100) ,convert(decimal(19,2) ,Amount)) + '" ' +
	   'minutes="' + convert(varchar(100) ,convert(decimal(19,2) ,CallDurationMinutes)) + '" ' +
	   'trafficperiod="' + @InvoicePeriod + '" '+
	   'desc="Hubbing Usage Charges"/>'
from 
(
	select convert(varchar(100),convert(decimal(19,2) ,sum(Amount))) as Amount,
		  convert(varchar(100),convert(decimal(19,2) , sum(Minutes))) as CallDurationMinutes
	from #TempMonthlyFinancial

) as tbl1


insert into #TempBillingAccountXMLData (RecordData)
select '</summary>'

insert into #TempBillingAccountXMLData (RecordData)
select '<usagecharges '+
	   'g-totalamount-us="' + convert(varchar(100) ,convert(decimal(19,2) ,Amount)) + '"'+
	   ' g-totalminutes="' + convert(varchar(100) ,convert(decimal(19,2) ,CallDurationMinutes)) + '">'
from 
(
	select convert(varchar(100),convert(decimal(19,2) ,sum(Amount))) as Amount,
		  convert(varchar(100),convert(decimal(19,2) , sum(Minutes))) as CallDurationMinutes
	from #TempMonthlyFinancial
) as tbl1



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

insert into #TempBillingAccountXMLData (RecordData)
select '</usagecharges>'

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
select '<bankdetails email="ABS_Finance_Operations@axiata.com" '+
	   'enquiry=" " accountname="Axiata Global Services Pte. Ltd." '+
	   'swiftcode="SCBLSG22" bankaccount="'+ BankAccount +'" '+
	   'address1="Marina Bay Financial Centre Branch," address2="8 Marina Boulevard," '+
	   'address3="#01-01, Marina Bay Financial Centre Tower 1," '+
	   'address4="Singapore 018981." '+
	   'bankname="Standard Chartered Bank (Singapore) Limited"/>'
from tb_BillingAccountInfo
where AccountID = @AccountID

insert into #TempBillingAccountXMLData (RecordData)
select '</invoice>'

select *
from #TempBillingAccountXMLData
order by RecordID

-----------------------------------------
-- Output the desired results to file
-----------------------------------------

if exists ( select 1 from #TempBillingAccountXMLData)
Begin


        Declare	@RecordFile varchar(500),
				@datestring varchar(100),
			    @bcpCommand varchar(5000),
			    @FileExists int,
			    @res int,
			    @QualifiedTableName varchar(500)

         select @datestring = CONVERT(varchar(50), getdate(), 20)
         select @datestring = REPLACE(@datestring, ':', '')
         select @datestring = REPLACE(@datestring, '-', '')
         select @datestring = ltrim(rtrim(REPLACE(@datestring, ' ', '')))	

		 set @ExtractFileName = @FileExtractPath + @Filename + '.xml'

		 -- Delete any pre-existing instance of the XML file

		 set @FileExists = 0

		Exec master..xp_fileexist  @ExtractFileName , @FileExists output 

		if ( @FileExists = 1 )
		Begin

		        set @bcpCommand = 'del '+ @ExtractFileName
				EXEC master..xp_cmdshell @bcpCommand 

		End

		 -- Create the file with all the records

		 set @QualifiedTableName = 'TempStatementXML_'+@datestring

		 if exists ( select 1 from sysobjects where name = @QualifiedTableName and xtype = 'U')
			Exec('Drop table ' + @QualifiedTableName)

         -- Move the data from the temporary table to the qualified table
		 Exec('select * into '+ @QualifiedTableName + ' from #TempBillingAccountXMLData')

         Set @QualifiedTableName = db_name() + '.dbo.' + @QualifiedTableName

         SET @bcpCommand = 'bcp "SELECT RecordData from ' + @QualifiedTableName + ' order by RecordID" queryout ' + '"' + ltrim(rtrim(@ExtractFileName )) + '"' + ' -c -r"\n" -T -S '+ @@servername
         --print @bcpCommand 

         EXEC master..xp_cmdshell @bcpCommand

		 -- Check if the XML File exists or not

		 set @FileExists = 0

		 Exec master..xp_fileexist  @ExtractFileName , @FileExists output 

		 if ( @FileExists <> 1 )
		 Begin

			set @ErrorMsgStr = 'Error !!! XML File : (' + @ExtractFileName + ') not created.'
			Raiserror('%s' , 16 , 1, @ErrorMsgStr)

			set @ExtractFileName = NULL

			GOTO ENDPROCESS	

		 End

End

Else
Begin

		set @ErrorMsgStr = 'Error !!! No billable Traffic data found for account in the provided date period'
		Raiserror('%s' , 16 , 1, @ErrorMsgStr)

		set @ExtractFileName = NULL

		GOTO ENDPROCESS	

End

ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempMonthlyFinancial') )
		Drop table #TempMonthlyFinancial

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempBillingAccountXMLData') )	
	Drop table #TempBillingAccountXMLData

if exists ( select 1 from sysobjects where name = 'TempStatementXML_'+ @datestring and xtype = 'U')
	Exec('Drop table ' + 'TempStatementXML_'+ @datestring)
GO
