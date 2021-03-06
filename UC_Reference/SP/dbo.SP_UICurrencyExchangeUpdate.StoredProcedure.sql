USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICurrencyExchangeUpdate]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_UICurrencyExchangeUpdate]
(
    @ExchangeID int,
	@ExchangeRate decimal(19,6),
	@UserID int, 
	@ErrorDescription varchar(2000) output,
	@ResultFlag int output
)
As

set @ResultFlag = 0
set @ErrorDescription = NULL

if ( @ExchangeID is NULL )
Begin

		set @ErrorDescription = 'ERROR!!! ExchangeID cannot be NULL'
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

Begin Try

	update tb_Exchange
	set ExchangeRate = @ExchangeRate ,
	    ModifiedDate = getdate(),
		ModifiedByID = @UserID
	where ExchangeID = @ExchangeID

	
End Try

Begin Catch

		set @ErrorDescription = 'ERROR!!! Updating Exchange Rate for currency. ' + ERROR_MESSAGE()
		set @ResultFlag = 1
		Return 1

End Catch
GO
