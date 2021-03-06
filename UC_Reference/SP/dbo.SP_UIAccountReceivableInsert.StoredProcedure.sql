USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIAccountReceivableInsert]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIAccountReceivableInsert]
(
	@AccountID int,
	@AccountReceivableTypeID int,
	@Amount Decimal(19,2),
	@PostingDate Date,
	@CurrencyID int,
	@ExchangeRate Decimal(19,4),
	@Description varchar(500),
	@UserID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ResultFlag = 0
set @ErrorDescription = NULL


-------------------------------------------------------------
-- Check to see if the Account is Not NULL or invalid value
-------------------------------------------------------------
if ((@AccountID is NULL) or not exists (Select 1 from tb_Account where AccountID = @AccountID and flag & 32 <>32))
Begin

	set @ErrorDescription = 'ERROR !!!! Account ID passed is NULL or does not exist in the system or is in inactive status'
	set @ResultFlag = 1
	return 1	

End


-------------------------------------------------------------------------
-- Check to see if the AccountReceivableType is Not NULL or invalid value
-------------------------------------------------------------------------
if ((@AccountReceivableTypeID is NULL) or not exists (Select 1 from tb_AccountReceivableType where AccountReceivableTypeID = @AccountReceivableTypeID and flag & 1 <> 1))
Begin

	set @ErrorDescription = 'ERROR !!!! Account Receivable Type ID passed is NULL or does not exist in the system or is in inactive status'
	set @ResultFlag = 1
	return 1	

End


-------------------------------------------------------------------------
-- Check to see if the Currency is Not NULL or invalid value
-------------------------------------------------------------------------

if ((@CurrencyID is NULL) or not exists (Select 1 from tb_Currency where CurrencyID = @CurrencyID and flag & 1 <> 1))
Begin

	set @ErrorDescription = 'ERROR !!!! Currency ID passed is NULL or does not exist in the system'
	set @ResultFlag = 1
	return 1	

End

-------------------------------------------------------------------------
-- Check to ensure that the posting date for the payment is in the 
-- month of the current date
-------------------------------------------------------------------------
if ( year(getdate()) <>  year(@PostingDate) )
Begin

	set @ErrorDescription = 'ERROR !!!! The posting date of the payment has to be in the year ' + convert(varchar(4) , year(getdate()) ) + '. It cannot be in a past year'
	set @ResultFlag = 1
	return 1
End

--------------------------------------------------------
-- Check to ensure that the payment is not in future
--------------------------------------------------------

if ( @PostingDate >  convert(date , getdate()))
Begin

	set @ErrorDescription = 'ERROR !!!! The posting date of payment cannot be in future'
	set @ResultFlag = 1
	return 1

End


-------------------------------------------------------------------------
-- Check to ensure that a valid description is added for the payment
-------------------------------------------------------------------------
if (@Description is NULL or (len(replace(@Description , ' ', '')) = 0))
Begin

	set @ErrorDescription = 'ERROR !!!! Please enter a valid description for the Account Receivable'
	set @ResultFlag = 1
	return 1

End

---------------------------------------------------------
-- Cannot create an account receivable for zero amount
---------------------------------------------------------

if (@Amount = 0)
Begin

	set @ErrorDescription = 'Error !!!! Account Receivable cannot be created for zero amount'
	set @ResultFlag = 1
	return 1

End

---------------------------------------------------------------------
-- The amount cannot be negative for Account Receivable Type Payment
---------------------------------------------------------------------
if (@Amount < 0 and @AccountReceivableTypeID = -1)
Begin

	set @ErrorDescription = 'ERROR !!!! Amount cannot be negative for payment type Account Receivable'
	set @ResultFlag = 1
	return 1

End

---------------------------------------------------------------------------
-- The amount cannot be greater than 0 for Refund , writeoff and Forfeit
---------------------------------------------------------------------------
if (@Amount > 0 and @AccountReceivableTypeID in (-5,-3,-2))
Begin

	set @ErrorDescription = 'ERROR !!!! Amount cannot be postive for refund , writeoff or forfeit type Account Receivable'
	set @ResultFlag = 1
	return 1

End

---------------------------------------------------------
-- The Exchange rate cannot be zero or negative values
---------------------------------------------------------
if (@ExchangeRate < = 0 )
Begin

	set @ErrorDescription = 'ERROR !!!! Exchange Rate cannot be negative or zero value'
	set @ResultFlag = 1
	return 1

End

--------------------------------------------------------------------------
-- Get the statement number, based on whether the account is international 
-- or Related partner
--------------------------------------------------------------------------
Declare @RelatedPartner int  = 0, -- Default is to consider as international partner
		@StatementPrefix varchar(100),
		@RelatedPartyList varchar(2000)

select @RelatedPartyList = ','+replace(rtrim(ltrim(ConfigValue)), ' ' , '')+','
from UC_Admin.dbo.tb_Config
where configname = 'RelatedParty'
and AccessScopeID = -4

if (@RelatedPartyList is NULL)
Begin

	set @RelatedPartner = 0

End

else
Begin

	select @RelatedPartner = 
				Case
					When charindex( ',' + convert(varchar(10) , @AccountID) + ',' , @RelatedPartyList ) > 0 then 1
					Else 0
				End

End

if (@RelatedPartner = 1) -- Use the statement prefix for local partner
Begin

	Select @StatementPrefix = rtrim(ltrim(ConfigValue))
	from UC_Admin.dbo.tb_Config
	where configname = 'RelatedPrePaidInvoicePrefix'
	and AccessScopeID = -4 

	if (@StatementPrefix is NULL)
	Begin

		set @ErrorDescription = 'ERROR !!! Statement Prefix for Local Partners is not configured (RelatedPrePaidInvoicePrefix) '
		set @ResultFlag = 1
		return 1

	End

End

else
Begin

	Select @StatementPrefix = rtrim(ltrim(ConfigValue))
	from UC_Admin.dbo.tb_Config
	where configname = 'InternationalPrePaidInvoicePrefix'
	and AccessScopeID = -4 

	if (@StatementPrefix is NULL)
	Begin

		set @ErrorDescription = 'ERROR !!! Statement Prefix for International Partners is not configured (InternationalPrePaidInvoicePrefix) '
		set @ResultFlag = 1
		return 1

	End

End

----------------------------------------------------------------
-- Get the latest statement number from the billing account info
-- and advance payment schema
----------------------------------------------------------------

Declare @StatementNumber varchar(100)

select @StatementNumber = isnull(@StatementPrefix +
       right('00000000' + convert(varchar(10),(max(convert(int ,substring(StatementNumber, len(@StatementPrefix) + 1 , len(StatementNumber)))) + 1)) , 8)
	   , @StatementPrefix +'00000001')
from
(
	select RevenueStatement as StatementNumber
	from Reportserver.UC_Report.dbo.tb_BillingAccountInfo
	where RevenueStatement is not NULL
	and isnumeric(substring(RevenueStatement ,len(@StatementPrefix) + 1 , len(RevenueStatement))) = 1

	union

	Select StatementNumber
	from Referenceserver.UC_Reference.dbo.tb_AccountReceivable
	where StatementNumber is not NULL
	and isnumeric(substring(StatementNumber ,len(@StatementPrefix) + 1 , len(StatementNumber))) = 1

) tbl1
where substring(StatementNumber , 1 ,  len(@StatementPrefix)) = @StatementPrefix

if (@StatementNumber is NULL)
Begin

		set @ErrorDescription = 'ERROR !!! Exception when deciphering the statement number for the invoice. Statement Number is NULL'
		set @ResultFlag = 1
		return 1

End


----------------------------------------------------------------
-- Insert data into the Account Receivable schema for the record
----------------------------------------------------------------
Begin Try

	insert into tb_AccountReceivable
	(
		AccountID,
		AccountReceivableTypeID,
		PostingDate,
		[Description],
		Amount,
		CurrencyID ,
		ExchangeRate,
		StatementNumber,
		PhysicalInvoice,
		ModifiedDate,
		ModifiedByID
	)
	values
	(
		@AccountID,
		@AccountReceivableTypeID,
		@PostingDate,
		@Description,
		@Amount,
		@CurrencyID,
		@ExchangeRate,
		@StatementNumber,
		NULL,
		getdate(),
		@UserID
	)

End Try

Begin Catch

	set @ErrorDescription = 'ERROR!!! Exception during insertion of Account Receivable record. ' + ERROR_MESSAGE()
	set @ResultFlag = 1
	return 1

End Catch





GO
