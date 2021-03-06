USE [UC_Report]
GO
/****** Object:  UserDefinedFunction [dbo].[FN_GetAmountInBaseCurrency]    Script Date: 5/2/2020 6:40:07 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Function [dbo].[FN_GetAmountInBaseCurrency]
(
	@Amount Decimal(19,6),
	@CurrencyID int,
	@EffectiveDate datetime
)
returns Decimal(19,6) 
As

Begin

		Declare @ConvertedAmount Decimal(19,6),
		        @ExchangeRate Decimal(19,4)

		Select @ExchangeRate = tbl1.ExchangeRate
		from ReferenceServer.UC_Reference.dbo.tb_Exchange tbl1
		inner join
		(
			select currencyID , max(BeginDate) as BeginDate
			from ReferenceServer.UC_Reference.dbo.tb_Exchange
			where BeginDate <= @EffectiveDate
			and currencyID = @CurrencyID
			group by currencyID

		) tbl2 on tbl1.CurrencyID = tbl2.CurrencyID
				and
				  tbl1.BeginDate = tbl2.BeginDate

        if ( @ExchangeRate is NULL )
		Begin
				set @ConvertedAmount = 0
		End

		Else
		Begin
				set @ConvertedAmount = convert(Decimal(19,6) , @Amount/@ExchangeRate)
		End

		Return @ConvertedAmount

End
GO
