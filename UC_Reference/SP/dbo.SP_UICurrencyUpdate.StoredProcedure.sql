USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICurrencyUpdate]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  Procedure [dbo].[SP_UICurrencyUpdate] (
 @CurrencyID int,
 @Currency varchar(30),
 @CurrencyAbbrv varchar(10),
 @CurrencySymbol varchar(8),
 @UserID int,
 @ErrorDescription varchar(2000) output,
 @ResultFlag int output
 ) AS

set @ErrorDescription = NULL
set @ResultFlag = 0

if exists ( 
				select 1 
				from tb_currency 
				where ( 
							Currency = @Currency or 
							CurrencyAbbrv = @CurrencyAbbrv or 
							CurrencySymbol = @CurrencySymbol 
					  ) 
				and currencyid <> @CurrencyID
          )
Begin


		set @ErrorDescription = 'ERROR!!! Currency Name, Abbreviation and Symbol should be unique'
		set @ResultFlag = 1
		Return 1


End


--------------------------------------------------
-- Update the record in database for the currency
--------------------------------------------------

Begin Try

	 Update tb_Currency
	 set Currency = @Currency,
	     CurrencyAbbrv = @CurrencyAbbrv,
		 CurrencySymbol = @CurrencySymbol,
		 ModifiedDate = GetDate(),
		 ModifiedByID = @UserID
	 where CurrencyID = @CurrencyID


End Try

Begin Catch

		set @ErrorDescription = 'ERROR!!! During update of currency record. '+ ERROR_MESSAGE()
		set @ResultFlag = 1
		Return 1

End Catch


Return 0

GO
