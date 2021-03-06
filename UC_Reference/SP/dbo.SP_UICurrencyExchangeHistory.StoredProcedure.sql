USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICurrencyExchangeHistory]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Procedure [dbo].[SP_UICurrencyExchangeHistory]
(
	@CurrencyID int
)
As

Select ExchangeID , ExchangeRate , BeginDate , ModifiedDate , UC_Admin.dbo.FN_GetUserName(ModifiedByID) as ModifiedByUser
from tb_Exchange
where CurrencyID = @CurrencyID
order by BeginDate Desc

GO
