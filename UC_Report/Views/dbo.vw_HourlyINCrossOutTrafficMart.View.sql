USE [UC_Report]
GO
/****** Object:  View [dbo].[vw_HourlyINCrossOutTrafficMart]    Script Date: 5/2/2020 6:39:07 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE View [dbo].[vw_HourlyINCrossOutTrafficMart]
As

select summ.CallDate , 
       right('0' + convert(varchar(2) ,summ.CallHour) ,2) + ':' + '00' as CallHour ,
       summ.CallDuration , summ.CircuitDuration,
       summ.Answered , summ.Seized,
	   summ.CallTypeID , isnull(ct.CallType  , '*****') as CallType,
	   summ.INAccountID , isnull(INAcc.Account , '*****') as INAccount,
	   summ.OutAccountID , isnull(OUTAcc.Account , '*****') as OUTAccount,
	   summ.INTrunkID , isnull(INTrnk.Trunk, '*****') as INTrunk,
	   summ.OUTTrunkID , isnull(OUTTrnk.Trunk , '*****') as OUTTrunk,
	   summ.INCommercialTrunkID , isnull(INCommTrnk.Trunk , '*****') as INCommercialTrunk,
	   summ.OUTCommercialTrunkID , isnull(OUTCommTrnk.Trunk , '*****') as OUTCommercialTrunk,
	   summ.INDestinationID , isnull(INDest.Destination , '*****') as INDestination,
	   summ.OUTDestinationID , isnull(OUTDest.Destination , '*****') as OUTDestination,
	   summ.RoutingDestinationID , isnull(RDest.Destination , '*****') as RoutingDestination,
	   summ.INServiceLevelID , isnull(INSl.ServiceLevel , '*****') as INServiceLevel,
	   summ.OUTServiceLevelID , isnull(OUTSl.ServiceLevel , '*****') as OUTServiceLevel,
	   summ.INRoundedCallDuration , summ.OUTRoundedCallDuration,
	   summ.INChargeDuration , summ.OUTChargeDuration
from tb_HourlyINCrossOutTrafficMart summ
left join ReferenceServer.UC_Reference.dbo.tb_Account INAcc on summ.INAccountID = INAcc.AccountID
left join ReferenceServer.UC_Reference.dbo.tb_Account OUTAcc on summ.OUTAccountID = OUTAcc.AccountID
left join ReferenceServer.UC_Reference.dbo.tb_Trunk INTrnk on summ.INTrunkID = INTrnk.TrunkID
left join ReferenceServer.UC_Reference.dbo.tb_Trunk OUTTrnk on summ. OUTTrunkID = OUTTrnk.TrunkID
left join ReferenceServer.UC_Reference.dbo.tb_Trunk INCommTrnk on summ.INCommercialTrunkID = INCommTrnk.TrunkID
left join ReferenceServer.UC_Reference.dbo.tb_Trunk OUTCommTrnk on summ.OUTCommercialTrunkID = OUTCommTrnk.TrunkID
left join ReferenceServer.UC_Reference.dbo.tb_Destination INDest on summ.INdestinationID = INDest.DestinationID
left join ReferenceServer.UC_Reference.dbo.tb_Destination OUTDest on summ.OUTdestinationID = OUTDest.DestinationID
left join ReferenceServer.UC_Reference.dbo.tb_Destination RDest on summ.RoutingdestinationID = RDest.DestinationID
left join ReferenceServer.UC_Reference.dbo.tb_ServiceLevel INSl on summ.INServiceLevelID = INSl.ServiceLevelID
left join ReferenceServer.UC_Reference.dbo.tb_ServiceLevel OUTSl on summ.OUTServiceLevelID = OUTSl.ServiceLevelID
left join ReferenceServer.UC_Reference.dbo.tb_CallType ct on summ.CallTypeID = ct.CallTypeID
GO
