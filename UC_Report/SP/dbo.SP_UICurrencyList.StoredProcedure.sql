USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICurrencyList]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create  Procedure [dbo].[SP_UICurrencyList] 

As

select tbl1.CurrencyID as ID , tbl1.Currency As [Name]
from ReferenceServer.UC_Reference.dbo.tb_currency tbl1
where tbl1.Flag & 1 <> 1


Return 0
GO
