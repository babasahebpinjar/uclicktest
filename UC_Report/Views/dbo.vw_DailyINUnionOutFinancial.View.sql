USE [UC_Report]
GO
/****** Object:  View [dbo].[vw_DailyINUnionOutFinancial]    Script Date: 5/2/2020 6:39:07 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE View [dbo].[vw_DailyINUnionOutFinancial]
As 

select summ.CallDate ,
       summ.DirectionID , dir.Direction,
	   summ.CallDuration , summ.CircuitDuration , summ.Answered, summ.Seized,
	   summ.CalltypeID , isnull(ct.CallType , '*****') as CallType,
	   summ.AccountID , isnull(acc.Account , '******') as Account,
	   summ.TrunkID , isnull(trnk.Trunk , '*****') as Trunk,
	   summ.CommercialTrunkID , isnull(ctrnk.Trunk , '*****') as CommercialTrunk,
	   summ.SettlementDestinationID , isnull(dest.Destination , '*****') as SettlementDestination,
	   summ.RoutingDestinationID , isnull(rdest.Destination , '*****') as RoutingDestination,
	   isnull(cou.CountryID, -1) as CountryID , isnull(cou.Country , '*****') as Country,
	   summ.INServiceLevelID , isnull(insl.ServiceLevel , '*****') as INServiceLevel,
	   summ.OutServiceLevelID , isnull(osl.ServiceLevel , '*****') as OUTServiceLevel,
	   summ.RatePlanID , isnull(rp.RatePlan , '******') as RatePlan,
	   summ.RatingMethodID , isnull(rm.RatingMethod , '*****') as RatingMethod,
	   summ.RoundedCallDuration , summ.ChargeDuration , summ.Amount , 
	   --dbo.FN_GetAmountInBaseCurrency(summ.Amount , summ.CurrencyID , summ.CallDate) as AmountBaseCurrency,
	   summ.Rate,
	   summ.RateTypeID , isnull(rti.RateItemName , '*****') as Ratetype,
	   summ.CurrencyID , isnull(curr.Currency , '*****') as Currency,
	   Case
	         When summ.ErrorIndicator = 1 then 'Error'
			 Else 'No Error'
	   End as ErrorIndicator
from tb_DailyINUnionOutFinancial summ
left join REFERENCESERVER.UC_REference.dbo.tb_Direction dir on summ.DirectionID = dir.DirectionID
left join REFERENCESERVER.UC_REference.dbo.tb_Calltype ct on summ.CalltypeID = ct.CallTypeID
left join REFERENCESERVER.UC_REference.dbo.tb_Account acc on summ.AccountID = acc.AccountID
left join REFERENCESERVER.UC_REference.dbo.tb_Trunk trnk on summ.TrunkID = trnk.TrunkID
left join REFERENCESERVER.UC_REference.dbo.tb_Trunk ctrnk on summ.CommercialTrunkID = ctrnk.TrunkID
left join REFERENCESERVER.UC_REference.dbo.tb_Destination dest on summ.SettlementDestinationID = dest.DestinationID
left join REFERENCESERVER.UC_REference.dbo.tb_Destination rdest on summ.RoutingDestinationID = rdest.DestinationID
left join REFERENCESERVER.UC_REference.dbo.tb_Country cou on rdest.CountryID = cou.CountryID
left join REFERENCESERVER.UC_REference.dbo.tb_ServiceLevel insl on summ.INServiceLevelID = insl.ServiceLevelID
left join REFERENCESERVER.UC_REference.dbo.tb_ServiceLevel osl on summ.OutServiceLevelID = osl.ServiceLevelID
left join REFERENCESERVER.UC_REference.dbo.tb_RatePlan rp on summ.RatePlanID = rp.RatePlanID
left join REFERENCESERVER.UC_REference.dbo.tb_RatingMethod rm on summ.RatingMethodID = rm.RatingmethodID
left join REFERENCESERVER.UC_REference.dbo.tb_RateItem rti on summ.RatetypeID = rti.RateItemID
left join REFERENCESERVER.UC_REference.dbo.tb_Currency curr on summ.CurrencyID = curr.CurrencyID



GO
