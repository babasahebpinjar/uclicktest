USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[Temp_InvoiceInfoXML]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--select INAccount , 
--       convert(decimal(19,2),sum(ISNull(INAmount ,0)) ) as Amount,
--	   convert(decimal(19,2),sum(CalldurationMinutes)) as Minutes,
--	   convert(decimal(19,2), convert(decimal(19,2),sum(ISNull(INAmount ,0)))/convert(decimal(19,2),sum(CalldurationMinutes))) as Rate
--from tb_CDRFileDataAnalyzed
--group by INAccount
--having sum(CalldurationMinutes) > 0


--select OutAccount , 
--       convert(decimal(19,2),sum(ISNull(OutAmount ,0)) ) as Amount,
--	   convert(decimal(19,2),sum(CalldurationMinutes)) as Minutes,
--	   convert(decimal(19,2), convert(decimal(19,2),sum(ISNull(OutAmount ,0)))/convert(decimal(19,2),sum(CalldurationMinutes))) as Rate
--from tb_CDRFileDataAnalyzed
--group by OutAccount
--having sum(CalldurationMinutes) > 0
CREATE procedure [dbo].[Temp_InvoiceInfoXML] as


Declare @InAccount varchar(100) = 'WorldHub',
        @InvoiceDate datetime = '2018-07-31',
		@InvoicePeriod varchar(50) = 'JULY 2018',
		@ExchangeRate Decimal(19,4) = 1.3638,
		@GSTPercent decimal(19,2) = 0.07,
		@TaxInvoice varchar(100) = 'SSG2/IB/0000001',
		@Filename varchar(500) = 'WorldHub_Inbound_Jul2018_Invoice'

Declare @InvoiceDueDate datetime  = DateAdd(dd , 30,@InvoiceDate )

-- Create a temporary table to insert all the XML data

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
select '<invoice duedate="'+ replace(upper(convert(varchar(100) , @InvoiceDueDate , 106)), ' ', '-') +'" '+ 
        'paymenterm="30 DAYS" ' +
		'invoicedate="'+ replace(upper(convert(varchar(100) , @InvoiceDate , 106)), ' ' ,'-') +'" '+ 
		'invoiceperiod="'+@InvoicePeriod +'" '+
		'taxinvoice="' + @TaxInvoice + '" '+
		'filename="' + @Filename + '" >'

insert into #TempBillingAccountXMLData (RecordData)
Select '<summary usdvalue="'+ convert(varchar(100), @ExchangeRate) + ' SGD' + '" '+
  	   'total-sg="' + convert(varchar(100) ,convert(decimal(19,2) ,sum(convert(Decimal(19,2),isnull(INAmount,0))) * @ExchangeRate * (1 + @GSTPercent))) + '" ' +
	   'total-us="' + convert(varchar(100) ,convert(decimal(19,2) ,sum(convert(decimal(19,2),isnull(INAmount,0))) * (1 + @GSTPercent))) + '" '+
	   'gst-sg="' + convert(varchar(100) ,convert(decimal(19,2) ,sum(convert(decimal(19,2),isnull(INAmount,0))) * @ExchangeRate * @GSTPercent)) + '" '+
	   'gst-us="' + convert(varchar(100) ,convert(decimal(19,2) ,sum(convert(decimal(19,2),isnull(INAmount,0))) * @GSTPercent)) + '" '+
	   'subtotal-sg="' + convert(varchar(100) ,convert(decimal(19,2) ,sum(convert(decimal(19,2),isnull(INAmount,0))) * @ExchangeRate)) + '" ' +
	   'subtotal-us="' + convert(varchar(100) ,convert(decimal(19,2) ,sum(convert(decimal(19,2),isnull(INAmount,0))))) + '" ' +
	   'gst-percent="' + convert(varchar(100) ,@GSTPercent*100) + '">' 
from 
(
	select convert(varchar(100),convert(decimal(19,2) ,sum(isnull(convert(decimal(19,2),INAmount),0)))) as INAmount,
		  convert(varchar(100) ,convert(decimal(19,4) ,isnull(INRate,0))) as INRate,
		  Destination
	from tb_CDRFileDataAnalyzed
	where INAccount = @InAccount
	and Callduration > 0
	group by isnull(INRate,0), Destination
	having convert(decimal(19,2) ,sum(isnull(INAmount,0))) > 0
) as tbl1

insert into #TempBillingAccountXMLData (RecordData)
Select '<traffic '+
	   'amount-sg="' + convert(varchar(100) ,convert(decimal(19,2) ,sum(convert(decimal(19,2),isnull(INAmount,0))) * @ExchangeRate)) + '" ' +
	   'amount-us="' + convert(varchar(100) ,convert(decimal(19,2) ,sum(convert(decimal(19,2),isnull(INAmount,0))))) + '" ' +
	   'minutes="' + convert(varchar(100) ,convert(decimal(19,2) ,sum(convert(decimal(19,2),CallDurationMinutes)))) + '" ' +
	   'trafficperiod="' + @InvoicePeriod + '" '+
	   'desc="Hubbing Usage Charges"/>'
from 
(
	select convert(varchar(100),convert(decimal(19,2) ,sum(isnull(convert(decimal(19,2),INAmount),0)))) as INAmount,
		  convert(varchar(100),convert(decimal(19,2) , sum(convert(decimal(19,2),CallDurationMinutes)))) as CallDurationMinutes,
		  convert(varchar(100) ,convert(decimal(19,4) ,isnull(INRate,0))) as INRate,
		  Destination
	from tb_CDRFileDataAnalyzed
	where INAccount = @InAccount
	and Callduration > 0
	group by isnull(INRate,0), Destination
	having convert(decimal(19,2) ,sum(isnull(INAmount,0))) > 0
) as tbl1

insert into #TempBillingAccountXMLData (RecordData)
select '</summary>'

insert into #TempBillingAccountXMLData (RecordData)
select '<usagecharges '+
	   'g-totalamount-us="' + convert(varchar(100) ,convert(decimal(19,2) ,sum(convert(decimal(19,2),isnull(INAmount,0))))) + '"'+
	   ' g-totalminutes="' + convert(varchar(100) ,convert(decimal(19,2) ,sum(convert(decimal(19,2),CallDurationMinutes)))) + '">'
from 
(
	select convert(varchar(100),convert(decimal(19,2) ,sum(isnull(convert(decimal(19,2),INAmount),0)))) as INAmount,
		  convert(varchar(100),convert(decimal(19,2) , sum(convert(decimal(19,2),CallDurationMinutes)))) as CallDurationMinutes,
		  convert(varchar(100) ,convert(decimal(19,4) ,isnull(INRate,0))) as INRate,
		  Destination
	from tb_CDRFileDataAnalyzed
	where INAccount = @InAccount
	and Callduration > 0
	group by isnull(INRate,0), Destination
	having convert(decimal(19,2) ,sum(isnull(INAmount,0))) > 0
) as tbl1

insert into #TempBillingAccountXMLData (RecordData)
select '<hubbingcharges '+
       'trafficperiod="' + @InvoicePeriod + '" '+
	   'totalamount-us="' + convert(varchar(100) ,convert(decimal(19,2) ,sum(convert(decimal(19,2),isnull(INAmount,0))))) + '" '+
	   'totalminutes="' + convert(varchar(100) ,convert(decimal(19,2) ,sum(convert(decimal(19,2),CallDurationMinutes)))) + '" ' +
	   'totalnoofcalls="' + convert(varchar(100) , sum(TotalCalls)) + '">'
from 
(
	select convert(varchar(100),convert(decimal(19,2) ,sum(isnull(convert(decimal(19,2),INAmount),0)))) as INAmount,
		  convert(varchar(100),convert(decimal(19,2) , sum(convert(decimal(19,2),CallDurationMinutes)))) as CallDurationMinutes,
		  convert(varchar(100) ,convert(decimal(19,4) ,isnull(INRate,0))) as INRate,
		   sum(
					Case
						When CallDuration > 0 then 1
						Else 0
				   End
			  ) as TotalCalls,
		  Destination
	from tb_CDRFileDataAnalyzed
	where INAccount = @InAccount
	and Callduration > 0
	group by isnull(INRate,0), Destination
	having convert(decimal(19,2) ,sum(isnull(INAmount,0))) > 0
) as tbl1


insert into #TempBillingAccountXMLData (RecordData)
select '<hubbingcharge ' +
       'amount-us = "' + convert(varchar(100),convert(decimal(19,2) ,sum(isnull(convert(decimal(19,2),INAmount),0)))) + '"' +
       ' minutes = "' + convert(varchar(100),convert(decimal(19,2) , sum(convert(decimal(19,2),CallDurationMinutes)))) + '"' +
	   ' rate = "' + convert(varchar(100) ,convert(decimal(19,4) ,isnull(INRate,0))) + '"' +
	   ' noofcalls= "'+
	   convert(varchar(100),
	   sum(
				Case
					When CallDuration > 0 then 1
					Else 0
			   End
		  )) + '"' +
	   ' enddate="'+ convert(varchar(100) ,max(CallDate), 106) + '"' +
	   ' startdate="' + convert(varchar(100),min(CallDate), 106)+ '"'+
	   ' dest="' +Destination + '"/>'
from tb_CDRFileDataAnalyzed
where INAccount = @InAccount
and Callduration > 0
group by isnull(INRate,0), Destination
having convert(decimal(19,2) ,sum(isnull(INAmount,0))) > 0
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
where Account = @InAccount

insert into #TempBillingAccountXMLData (RecordData)
select '<companyname>' + CompanyName +  Case when right(CompanyName,1) <> ',' then ',' else '' End +'</companyname>'
from tb_BillingAccountInfo
where Account = @InAccount

insert into #TempBillingAccountXMLData (RecordData)
select '<address1>'+ Address1 +  Case when (Address2 is not null) and right(Address1,1) <> ',' then ',' else '' End + '</address1>'
from tb_BillingAccountInfo
where Account = @InAccount

insert into #TempBillingAccountXMLData (RecordData)
select '<address2>'+ Address2 +  Case when (Address3 is not null) and right(Address2,1) <> ',' then ',' else '' End + '</address2>'
from tb_BillingAccountInfo
where Account = @InAccount

insert into #TempBillingAccountXMLData (RecordData)
select '<address3>'+ Address3 +  Case when (Address4 is not null) and right(Address3,1) <> ',' then ',' else '' End + '</address3>'
from tb_BillingAccountInfo
where Account = @InAccount

insert into #TempBillingAccountXMLData (RecordData)
select '<address4>'+ isnull(Address4,'') + '</address4>'
from tb_BillingAccountInfo
where Account = @InAccount

insert into #TempBillingAccountXMLData (RecordData)
select '<email>'+ EmailAddress + '</email>'
from tb_BillingAccountInfo
where Account = @InAccount

insert into #TempBillingAccountXMLData (RecordData)
select '</toaddress>'

insert into #TempBillingAccountXMLData (RecordData)
select '<bankdetails email="ABS_Finance_Operations@axiata.com" '+
	   'enquiry=" " accountname="Axiata Global Services Pte. Ltd." '+
	   'swiftcode="SCBLSGSG" bankaccount="0101964544" '+
	   'address1="Marina Bay Financial Centre Branch," address2="8 Marina Boulevard," '+
	   'address3="#01-01, Marina Bay Financial Centre Tower 1," '+
	   'address4="Singapore 018981." '+
	   'bankname="Standard Chartered Bank"/>'

insert into #TempBillingAccountXMLData (RecordData)
select '</invoice>'

select RecordData from #TempBillingAccountXMLData order by RecordId asc

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempBillingAccountXMLData') )	
	Drop table #TempBillingAccountXMLData
GO
