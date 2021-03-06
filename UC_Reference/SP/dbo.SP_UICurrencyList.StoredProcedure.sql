USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICurrencyList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  Procedure [dbo].[SP_UICurrencyList] 
(
	@CurrencyID int = NULL
)
As

select tbl1.CurrencyID , tbl1.Currency , tbl1.CurrencyAbbrv , tbl1.CurrencySymbol ,
tbl2.ExchangeRate , tbl2.Begindate as ExchangeEffectiveDate, tbl1.ModifiedDate ,
uc_admin.dbo.FN_GetUserName(tbl1.ModifiedbyID) as ModifiedByUser
from tb_currency tbl1
left join
(
		select Ex.ExchangeRate , Ex.CurrencyID , Ex.BeginDate
		from tb_Exchange Ex
		inner join
		(
			Select currencyID , Max(BeginDate) as BeginDate
			from tb_Exchange 
			where BeginDate <= convert(date , getdate())
			group by currencyID
		) ExDet
		on Ex.CurrencyID = ExDet.CurrencyID
		and Ex.BeginDate = ExDet.BeginDate
) tbl2
on tbl1.CurrencyID = tbl2.CurrencyID
where tbl1.Flag & 1 <> 1
and tbl1.CurrencyID = isnull(@CurrencyID , tbl1.CurrencyID)


Return 0
GO
