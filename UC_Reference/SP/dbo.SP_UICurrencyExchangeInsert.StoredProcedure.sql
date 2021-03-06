USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICurrencyExchangeInsert]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_UICurrencyExchangeInsert]
(
	@CurrencyID int ,
	@ExchangeRate decimal(19,6),
	@BeginDate date,
	@UserID int, 
	@ErrorDescription varchar(2000) output,
	@ResultFlag int output
)
As

set @ResultFlag = 0
set @ErrorDescription = NULL

if ( @CurrencyID is NULL )
Begin

		set @ErrorDescription = 'ERROR!!! CurrencyID cannot be NULL'
		set @ResultFlag = 1
		Return 1

End

----------------------------------------------------
-- Check that not more than 4 decimal places are 
-- allowed in the conversion rates
----------------------------------------------------
if ( @ExchangeRate * 10000 - CONVERT(bigint , @ExchangeRate * 10000) > 0 )
Begin

		set @ErrorDescription = 'ERROR!!! Exchange rate cannot be more than 4 Decimal places'
		set @ResultFlag = 1
		Return 1

End

---------------------------------------------------
-- Check if an exchange rate record already exists
-- in the system for currency and begin date.
---------------------------------------------------

if exists ( select 1 from tb_exchange where currencyid = @CurrencyID and begindate = @BeginDate )
Begin

		set @ErrorDescription = 'ERROR!!! Exchange rate record already exists for the currency and begin date. Please use the edit option to change exchange rate'
		set @ResultFlag = 1
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

		set @ErrorDescription = 'ERROR!!! Inserting Exchange Rate for currency. ' + ERROR_MESSAGE()
		set @ResultFlag = 1
		Return 1

End Catch
GO
