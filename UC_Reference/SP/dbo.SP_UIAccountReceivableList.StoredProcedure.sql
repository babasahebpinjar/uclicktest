USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIAccountReceivableList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIAccountReceivableList]
(
	@AccountID int = NULL
)
As

Select tbl1.AccountReceivableID,
	   tbl1.Description,
	   tbl2.Account,
	   tbl3.AccountReceivableType,
	   tbl1.PostingDate,
	   tbl1.Amount,
	   tbl4.Currency,
	   tbl1.ExchangeRate,
	   tbl1.StatementNumber,
	   tbl1.PhysicalInvoice ,
	   tbl1.ModifiedDate,
	   tbl5.Name as ModifiedBy
from tb_AccountReceivable tbl1
inner join tb_Account tbl2 on tbl1.AccountID = tbl2.AccountID
inner join tb_AccountReceivableType tbl3 on tbl1.AccountReceivableTypeID = tbl3.AccountReceivableTypeID
inner join tb_Currency tbl4 on tbl1.CurrencyID = tbl4.CurrencyID
inner join UC_Admin.dbo.tb_Users tbl5 on tbl1.ModifiedByID = tbl5.UserID
where tbl1.AccountID = isnull(@AccountID , tbl1.AccountID)
order by tbl1.PostingDate desc

return 0
GO
