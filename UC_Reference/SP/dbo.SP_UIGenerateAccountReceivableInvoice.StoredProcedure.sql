USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGenerateAccountReceivableInvoice]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_UIGenerateAccountReceivableInvoice]
(
	@AccountReceivableID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

----------------------------------------------------------
-- Check if Account Receivable is Null or invalid value
----------------------------------------------------------
if ( (@AccountReceivableID is NULL ) or not exists (select 1 from tb_AccountReceivable where AccountReceivableID = @AccountReceivableID))
Begin

	set @ErrorDescription = 'ERROR !!! Account Receivable ID is either NULL or does not exist in the system.'
	set @ResultFlag = 1
	GOTO ENDPROCESS

End

------------------------------------------------------------------------
-- Get all the essential information from the Account Receivable Record
------------------------------------------------------------------------

Declare @Amount Decimal(19,2),
		@PostingDate Date,
		@AccountReceivableTypeID int,
		@CurrencyID int,
		@PhysicalInvoice varchar(500),
		@AccountID int,
		@AccountReceivableType varchar(100),
		@ExchangeRate Decimal(19,4),
		@TaxInvoice varchar(100)

select @Amount = Amount,
	   @PostingDate = PostingDate,
	   @AccountReceivableTypeID = AccountReceivableTypeID,
	   @AccountID = AccountID,
	   @CurrencyID = CurrencyID,
	   @ExchangeRate = ExchangeRate,
	   @TaxInvoice  = StatementNumber
from tb_AccountReceivable
where AccountReceivableID = @AccountReceivableID

select @AccountReceivableType = AccountReceivableType
from tb_AccountReceivableType
where AccountReceivableTypeID = @AccountReceivableTypeID

------------------------------------------------------
-- Depending on the home country of the account decide
-- whether this is intenational or local partner
-----------------------------------------------------
Declare @LocalPartner int  = 0, -- Default is to consider as international partner
		@LocalPartnerCountry varchar(60)

Select @LocalPartnerCountry = rtrim(ltrim(ConfigValue))
from UC_Admin.dbo.tb_Config
where configname = 'LocalPartnerCountry'
and AccessScopeID = -4

if (@LocalPartnerCountry is NULL)
Begin

	set @ErrorDescription = 'ERROR !!! Domestic Country needs to be configured for identifying local partners (LocalPartnerCountry)'
	set @ResultFlag = 1
	GOTO ENDPROCESS

End


select @LocalPartner = 
			Case
				When isnull(tbl2.Country, 'Not Available') = @LocalPartnerCountry then 1
				Else 0
			End
From ReferenceServer.UC_Reference.dbo.tb_Account tbl1
left join ReferenceServer.UC_Reference.dbo.tb_Country tbl2 on tbl1.CountryID = tbl2.CountryID
where tbl1.AccountID = @AccountID


--------------------------------------------------------------------------------------------
-- Get the Exchange Rate based on whether the advance payment is for local or international
-- parnter
--------------------------------------------------------------------------------------------

if (@LocalPartner = 0)
Begin

	set @ExchangeRate = 1 -- We go with the assumption that everything else in the system is in system currency

End

-- Debug Start
-- select @ExchangeRate
-- Debug End

----------------------------------------------------------
-- Get the GST percentage to be used from the config table
----------------------------------------------------------

Declare @GSTPercent decimal(19,2)

select @GSTPercent = convert(decimal(19,2) ,ConfigValue)
from UC_Admin.dbo.tb_Config
where Configname = 'GSTPercentFinance'
and AccessScopeID = -4

if (@GSTPercent is NULL)
	set @GSTPercent = 0 -- Default the value to 0 in case its not configured

-- Debug Start
-- select @GSTPercent
-- Debug End

--------------------------------------------------------------------------
-- Get the location where all the physical account receivable invoices
-- are created
--------------------------------------------------------------------------

Declare @PhysicalInvoiceFolder varchar(500)

select @PhysicalInvoiceFolder = ConfigValue
from UC_Admin.dbo.tb_Config
where Configname = 'AdvancePaymentInvoiceDirectory'
and AccessScopeID = -4

-- Debug Start
-- select @PhysicalInvoiceFolder
-- Debug End

----------------------------------------------
-- Throw Error, if the path is not configured
----------------------------------------------
if (@PhysicalInvoiceFolder is NULL)
Begin

	set @ErrorDescription = 'ERROR !!! Folder for generating physical account receivable invoices (AdvancePaymentInvoiceDirectory) is not configured'
	set @ResultFlag = 1
	GOTO ENDPROCESS

End

-------------------------------------------------------------
-- Check to ensure that the folder is a valid accessible path
-------------------------------------------------------------

Declare @cmd varchar(2000)

if ( RIGHT(@PhysicalInvoiceFolder , 1) <> '\' )
     set @PhysicalInvoiceFolder = @PhysicalInvoiceFolder + '\'

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempCommandoutput') )
	Drop table #tempCommandoutput

create table #tempCommandoutput
(
  CommandOutput varchar(500)
)

set @cmd = 'dir ' + '"' + @PhysicalInvoiceFolder + '"' + '/b'
--print @cmd

insert into #tempCommandoutput
	Exec master..xp_cmdshell @cmd

-- Debug Start
-- select @PhysicalInvoiceFolder
-- Debug End


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

    set @ErrorDescription = 'Error !!! Accessing the Folder path : (' + @PhysicalInvoiceFolder + ')'
	set @ResultFlag = 1
	GOTO ENDPROCESS

End

-----------------------------------------------------------------------------
-- Check to ensure that the invoice generation executable exists and is valid	
-----------------------------------------------------------------------------

Declare @InvoiceGenerateExecutable varchar(500)

select @InvoiceGenerateExecutable = ConfigValue
from UC_Admin.dbo.tb_Config
where Configname = 'ConvertAccountReceivableXMLToPDFScript'
and AccessScopeID = -4

------------------------------------------------------
-- Throw an exception if the configuration os NULL
------------------------------------------------------

if (@InvoiceGenerateExecutable is NULL)
Begin

	set @ErrorDescription = 'Error !!! Configuration for executable to generate invoices missing (ConvertAccountReceivableXMLToPDFScript)'
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

	set @ErrorDescription = 'Error !!! Executable to generate invoices for AR : (' + @InvoiceGenerateExecutable + ') does not exist or unaccessible.'
	set @ResultFlag = 1
	GOTO ENDPROCESS	

End


---------------------------------------------------------------
-- Build the name for the invoice XML file, that needs to be
-- generated
---------------------------------------------------------------
set @PhysicalInvoice = @AccountReceivableType + '_' +  replace(convert(varchar(10) , @PostingDate , 120) , '-' , '') + '_' +
                       convert(varchar(20) , @AccountReceivableID)

-- Debug Start
-- select @PhysicalInvoice
-- Debug End

-----------------------------------------------------------------
-- Build the complete name of the file that needs to be generated
-----------------------------------------------------------------
Declare @CompleteFileName varchar(500),
        @FinalInvoice varchar(500)


set @CompleteFileName = @PhysicalInvoiceFolder + @PhysicalInvoice + '.xml'
set @FinalInvoice = @PhysicalInvoiceFolder + @PhysicalInvoice + '.pdf'

-- Debug Start
-- select @CompleteFileName , @FinalInvoice
-- Debug End

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

-----------------------------------------------------------------
-- Create a temporary table to store the XML data for the file
-- to be generated
-----------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAccountReceivableXMLData') )	
	Drop table #TempAccountReceivableXMLData

Create table #TempAccountReceivableXMLData
(
	RecordID int identity(1,1),
	RecordData varchar(2000)
)

insert into #TempAccountReceivableXMLData (RecordData)
select '<?xml version="1.0" encoding="UTF-8"?>'

insert into #TempAccountReceivableXMLData (RecordData)
select '<invoice invoicedate="'+ replace(upper(convert(varchar(100) ,@PostingDate , 106)), ' ' ,'-') +'" '+ 
		'taxinvoice="' + @TaxInvoice + '" '+
		'filename="' + @PhysicalInvoice + '" ' +
		'modetype="advancepayment" >'
		------------------------------------------------------------------------
		-- Can be used in future. For AGS we will only go with "advancepayment"
		------------------------------------------------------------------------
		--Case
		--	When @AccountReceivableTypeID = -1 then 'modetype="advancepayment" >'
		--	When @AccountReceivableTypeID = -2 then 'modetype="forfeit" >'
		--	When @AccountReceivableTypeID = -3 then 'modetype="refund" >'
		--	When @AccountReceivableTypeID = -4 then 'modetype="adjustment" >'
		--	When @AccountReceivableTypeID = -5 then 'modetype="writeoff" >'
		--End
		

insert into #TempAccountReceivableXMLData (RecordData)
Select 
		Case
				When @LocalPartner = 0 then '<summary usdvalue="" '
				Else '<summary usdvalue="'+ convert(varchar(100), @ExchangeRate) + ' SGD' + '" '
		End +
		Case
				When @LocalPartner = 0 then 'total-sg="" '
				Else 'total-sg="' + 
						Case
							When @Amount < = 0 then '('+convert(varchar(100) ,convert(decimal(19,2) ,@Amount * @ExchangeRate * (1 + @GSTPercent))) + ')" '
							Else convert(varchar(100) ,convert(decimal(19,2) ,@Amount * @ExchangeRate * (1 + @GSTPercent))) + '" '
						End 
		End +
	   'total-us="' + 
			Case
				When @Amount < 0 then '('+convert(varchar(100) ,convert(decimal(19,2) ,@Amount * (1 + @GSTPercent))) + ')" '
				Else convert(varchar(100) ,convert(decimal(19,2) ,@Amount * (1 + @GSTPercent))) + '" '
			End +
		Case
				When @LocalPartner = 0 then 'gst-sg="" '
				Else 'gst-sg="' + 
					Case
						When @Amount < 0 then '('+convert(varchar(100) ,convert(decimal(19,2) ,@Amount * @ExchangeRate * @GSTPercent)) + ')" '
						Else convert(varchar(100) ,convert(decimal(19,2) ,@Amount * @ExchangeRate * @GSTPercent)) + '" '
					End 
		End +	   
	   'gst-us="' + 
			Case
				When @Amount < 0 then '('+convert(varchar(100) ,convert(decimal(19,2) ,@Amount * @GSTPercent)) + ')" '
				Else convert(varchar(100) ,convert(decimal(19,2) ,@Amount * @GSTPercent)) + '" '
			End +
		Case
				When @LocalPartner = 0 then 'subtotal-sg="" '
				Else 'subtotal-sg="' + 
					Case
						When @Amount < 0 then '('+ convert(varchar(100) ,convert(Decimal(19,2),@Amount * @ExchangeRate)) + ')" ' 
						Else convert(varchar(100) ,convert(Decimal(19,2),@Amount * @ExchangeRate)) + '" ' 
					End
		End +	   
	   'subtotal-us="' + 
			Case
				When @Amount < 0 then '(' +convert(varchar(100) ,@Amount) + ')" '
				Else convert(varchar(100) ,@Amount) + '" '  
			End +
	   'gst-percent="' + 
			Case
				When @Amount < 0 then '(' + convert(varchar(100) ,convert(int ,@GSTPercent*100)) + ')">' 
				Else convert(varchar(100) ,convert(int ,@GSTPercent*100)) + '">' 
			End

insert into #TempAccountReceivableXMLData (RecordData)
Select '<payment date="' +  upper(convert(varchar(100) ,@PostingDate , 106)) + '" '+
	   Case
			When @AccountReceivableTypeID = -1 then ' desc="Advance Payment for prepaid hubbing service"'+ ' '
			When @AccountReceivableTypeID = -2 then ' desc="Forfeit for prepaid hubbing service"'+ ' '
			When @AccountReceivableTypeID = -3 then ' desc="Refund for prepaid hubbing service"'+ ' '
			When @AccountReceivableTypeID = -4 then ' desc="Adjustment for prepaid hubbing service"'+ ' '
			When @AccountReceivableTypeID = -5 then ' desc="Writeoff for prepaid hubbing service"'+ ' '
	   End +
		Case
				When @LocalPartner = 0 then 'amount-sg="" '
				Else 'amount-sg="' + convert(varchar(100) ,convert(Decimal(19,2),@Amount * @ExchangeRate)) + '" '
		End +
	   'amount-us="' + convert(varchar(100) ,@Amount) + '"  />'

insert into #TempAccountReceivableXMLData (RecordData)
select '</summary>'

insert into #TempAccountReceivableXMLData (RecordData)
select '<toaddress>'

insert into #TempAccountReceivableXMLData (RecordData)
select '<name>'+ ContactName +  Case when right(ContactName,1) <> ',' then ',' else '' End + '</name>'
from ReportServer.UC_Report.dbo.tb_BillingAccountInfo
where AccountID = @AccountID

insert into #TempAccountReceivableXMLData (RecordData)
select '<companyname>' + CompanyName +  Case when right(CompanyName,1) <> ',' then ',' else '' End +'</companyname>'
from ReportServer.UC_Report.dbo.tb_BillingAccountInfo
where AccountID = @AccountID

insert into #TempAccountReceivableXMLData (RecordData)
select '<address1>'+ Address1 +  Case when (Address2 is not null) and right(Address1,1) <> ',' then ',' else '' End + '</address1>'
from ReportServer.UC_Report.dbo.tb_BillingAccountInfo
where AccountID = @AccountID

insert into #TempAccountReceivableXMLData (RecordData)
select '<address2>'+ Address2 +  Case when (Address3 is not null) and right(Address2,1) <> ',' then ',' else '' End + '</address2>'
from ReportServer.UC_Report.dbo.tb_BillingAccountInfo
where AccountID = @AccountID

insert into #TempAccountReceivableXMLData (RecordData)
select '<address3>'+ Address3 +  Case when (Address4 is not null) and right(Address3,1) <> ',' then ',' else '' End + '</address3>'
from ReportServer.UC_Report.dbo.tb_BillingAccountInfo
where AccountID = @AccountID

insert into #TempAccountReceivableXMLData (RecordData)
select '<address4>'+ isnull(Address4,'') + '</address4>'
from ReportServer.UC_Report.dbo.tb_BillingAccountInfo
where AccountID = @AccountID

insert into #TempAccountReceivableXMLData (RecordData)
select '<email>'+ EmailAddress + '</email>'
from ReportServer.UC_Report.dbo.tb_BillingAccountInfo
where AccountID = @AccountID

insert into #TempAccountReceivableXMLData (RecordData)
select '</toaddress>'

insert into #TempAccountReceivableXMLData (RecordData)
select '<otherinfo email="ABS_Finance_Operations@axiata.com" />'

insert into #TempAccountReceivableXMLData (RecordData)
select '</invoice>'

----------------------------------------------------------------
-- Mark all the special characters in XML to ensure it does not
-- fail in conversion
----------------------------------------------------------------
update #TempAccountReceivableXMLData
set RecordData = replace(RecordData , '&' , '&#38;')

-- Debug Start
--select *
--from #TempAccountReceivableXMLData
--order by RecordID
-- Debug End


--------------------------------------------------------------------
-- Publish the XML file created into the advance payment directory
--------------------------------------------------------------------

-----------------------------------------
-- Output the desired results to file
-----------------------------------------

if exists ( select 1 from #TempAccountReceivableXMLData)
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

		 set @QualifiedTableName = 'TempXML_'+ @PhysicalInvoice

		 if exists ( select 1 from sysobjects where name = @QualifiedTableName and xtype = 'U')
			Exec('Drop table ' + @QualifiedTableName)

         -- Move the data from the temporary table to the qualified table
		 Exec('select * into '+ @QualifiedTableName + ' from #TempAccountReceivableXMLData')

         Set @QualifiedTableName = db_name() + '.dbo.' + @QualifiedTableName

         SET @bcpCommand = 'bcp "SELECT RecordData from ' + @QualifiedTableName + ' order by RecordID" queryout ' + '"' + ltrim(rtrim(@CompleteFileName )) + '"' + ' -c -r"\n" -T -S '+ @@servername
         --print @bcpCommand 

         EXEC master..xp_cmdshell @bcpCommand

		 set @QualifiedTableName = 'TempXML_'+ @PhysicalInvoice

		 if exists ( select 1 from sysobjects where name = @QualifiedTableName and xtype = 'U')
		 Exec('Drop table ' + @QualifiedTableName)

		 -- Check if the XML File exists or not

		 set @FileExists = 0

		 Exec master..xp_fileexist  @CompleteFileName , @FileExists output 

		 if ( @FileExists <> 1 )
		 Begin

			set @ErrorDescription = 'Error !!! XML File : (' + @CompleteFileName + ') not created for invoice.'
			set @ResultFlag = 1
			GOTO ENDPROCESS	

		 End

End

Else
Begin

		set @ErrorDescription = 'Error !!! No Account Receivable information found to build the invoice XML'
		set @ResultFlag = 1
		GOTO ENDPROCESS	

End

--------------------------------------------------------------------------
-- Buld the command prompt execution command to generate the PDF invoice
--------------------------------------------------------------------------

set @cmd = '""' + @InvoiceGenerateExecutable + '" ' +  -- Added double quotes twice at beginning and end as xp_cmdshell requires it when running the command
           '"' + @CompleteFileName + '" ' +
		   '"' + @PhysicalInvoiceFolder + '\""' -- Added this "\" due to limitation of the invoice generation executable

-- Debug Start
--print @cmd
-- Debug End

----------------------------------------------------------------
-- Run the command using the XP_CMDSHELL to generate the invoice
----------------------------------------------------------------

Delete from #tempCommandoutput

insert into #tempCommandoutput
EXEC master..xp_cmdshell @cmd

-- Debug Start
--select *
--from #tempCommandoutput
-- Debug End

--------------------------------------------------------------------
-- Check if the invoice has been created and delete the xml file
--------------------------------------------------------------------
set @FileExists = 0

Exec master..xp_fileexist  @FinalInvoice , @FileExists output 

if ( @FileExists <> 1 )
Begin

		set @ErrorDescription = 'ERROR !!!! PDF Invoice File not created due to some exception'
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

		----------------------------------------------
		-- Update the Account Receivable record with
		-- name of the physical invoice file
		----------------------------------------------
		update tb_AccountReceivable
		set PhysicalInvoice = replace( @FinalInvoice, @PhysicalInvoiceFolder , '')
		where AccountReceivableID = @AccountReceivableID

End


ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempCommandoutput') )
	Drop table #tempCommandoutput

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAccountReceivableXMLData') )	
	Drop table #TempAccountReceivableXMLData

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempExchangeRate') )
		Drop table #tempExchangeRate
GO
