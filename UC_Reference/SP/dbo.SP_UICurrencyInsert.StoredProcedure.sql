USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICurrencyInsert]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  Procedure [dbo].[SP_UICurrencyInsert] (
 @Currency varchar(30),
 @CurrencyAbbrv varchar(10),
 @CurrencySymbol varchar(8),
 @ExchangeRate Decimal(19,6),
 @BeginDate Date,
 @UserID int,
 @ErrorDescription varchar(2000) output,
 @ResultFlag int output
 ) AS

set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @CurrencyID int

-------------------------------------------------------------
-- Ensure that Currency Name , Abbreviation and Symbol are not
-- null and unique values
-------------------------------------------------------------

if ( @Currency is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Name of currency cannot be NULL'
	set @ResultFlag = 1
	Return 1

End

if ( @CurrencyAbbrv is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Currency Abbreviation cannot be NULL'
	set @ResultFlag = 1
	Return 1

End

if ( @CurrencySymbol is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Currency Symbol cannot be NULL'
	set @ResultFlag = 1
	Return 1

End

--------------------------------------------------------
-- Ensure that Exchange Rate is not NULL and should be
-- postive numeric value
--------------------------------------------------------

if (
		( @ExchangeRate is NULL )
		or
		( isnumeric(@ExchangeRate) = 0 )
		or
		( @ExchangeRate < 0 )
   )
Begin

	set @ErrorDescription = 'ERROR !!! Exchange rate should be a numeric value greater than 0'
	set @ResultFlag = 1
	Return 1

End

----------------------------------------------------------------
-- Ensure that Currency Name , Abbreviation and Symbol are unique
-- values
-----------------------------------------------------------------

if exists (
				select 1 from tb_currency
				where ltrim(rtrim(Currency)) = ltrim(rtrim(@Currency))
				or ltrim(rtrim(CurrencyAbbrv)) = ltrim(rtrim(@CurrencyAbbrv))
				or ltrim(rtrim(CurrencySymbol)) = ltrim(rtrim(@CurrencySymbol))
          )
Begin

	set @ErrorDescription = 'ERROR !!! Currency Name , Abbreviation and Symbol should be unique values'
	set @ResultFlag = 1
	Return 1

End


Begin Transaction InsertRec

Begin Try

	 INSERT INTO tb_Currency
	   (
	   Currency,
	   CurrencyAbbrv,
	   CurrencySymbol,
	   ModifiedDate,
	   ModifiedByID,
	   Flag
	   )
	 VALUES 
	   (
	   @Currency,
	   @CurrencyAbbrv,
	   @CurrencySymbol,
	   GetDate(),
	   @UserID,
	   0 
	   )

End Try

Begin Catch

		set @ErrorDescription = 'ERROR!!! During creation of new currency record. '+ ERROR_MESSAGE()
		set @ResultFlag = 1
		Rollback Transaction InsertRec
		Return 1

End Catch

-----------------------------------------------------------
-- In case the currency record has been created, exchange
-- rate needs to be added for the same
-----------------------------------------------------------

----------------------------------------------------
-- Check that not more than 4 decimal places are 
-- allowed in the conversion rates
----------------------------------------------------
if ( @ExchangeRate * 10000 - CONVERT(bigint , @ExchangeRate * 10000) > 0 )
Begin

		set @ErrorDescription = 'ERROR!!! Exchange rate cannot be more than 4 Decimal places'
		set @ResultFlag = 1
		Rollback Transaction InsertRec
		Return 1

End

----------------------------------------------------
-- Get the unique currency identifier for inserting
-- exchange rate record
----------------------------------------------------

select @CurrencyID = currencyid
from tb_currency
where currency = @Currency
and CurrencyAbbrv = @CurrencyAbbrv
and CurrencySymbol = @CurrencySymbol

if ( @CurrencyID is NULL )
Begin

		set @ErrorDescription = 'ERROR!!! CurrencyID cannot be NULL'
		set @ResultFlag = 1
		Rollback Transaction InsertRec
		Return 1

End

Begin Try

	insert into tb_Exchange
	(
		ExchangeRate,
		CurrencyID,
		BeginDate,
		ModifiedDate,
		ModifiedByID,
		flag

	)
	values
	(
		@ExchangeRate,
		@CurrencyID,
		@BeginDate,
		getdate(),
		@UserID,
		0
	)

End Try

Begin Catch

		set @ErrorDescription = 'ERROR!!! Inserting Exchange Rate for currency : ' + @Currency 
		set @ResultFlag = 1
		Rollback Transaction InsertRec
		Return 1

End Catch

Commit Transaction InsertRec

Return 0
GO
