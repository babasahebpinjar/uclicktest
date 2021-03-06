USE [UC_Bridge]
GO
/****** Object:  View [dbo].[vw_VendorSource]    Script Date: 5/2/2020 6:44:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE     VIEW [dbo].[vw_VendorSource]
--With Encryption 
AS

select Src.SourceID ,Src.[Source] , Acc.AccountID , Acc.Account,
       Rp.RatePlanId , Rp.RatePlan , Cp.CalltypeId , Cp.Calltype,
	   Curr.CurrencyId , Curr.Currency 
from REferenceServer.UC_Commerce.dbo.tb_Source Src
inner join Referenceserver.uc_reference.dbo.tb_Account Acc on Src.ExternalCode = Acc.AccountID
inner join Referenceserver.uc_reference.dbo.tb_RatePlan Rp on Src.RatePlanID = Rp.RatePlanID
inner join Referenceserver.uc_reference.dbo.tb_Calltype Cp on Src.CalltypeID = Cp.CallTypeID
inner join Referenceserver.uc_reference.dbo.tb_Currency Curr on Src.CurrencyID = Curr.CurrencyID
where SourcetypeID = -1 -- Vendor Source
GO
