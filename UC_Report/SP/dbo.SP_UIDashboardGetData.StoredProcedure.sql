USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIDashboardGetData]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UIDashboardGetData]
As

-------------------------------------------------
-- Dashboard 1 : Last 30 days Terminating Traffic
-------------------------------------------------

select [CallDate] , [ServiceLevel] , [TotalMinutes]
from tb_DashboardGraphTerminatingTraffic
order by CallDate ,ServiceLevel


-------------------------------------------------
-- Dashboard 2 : Revenue Vs Cost for Current Month
-------------------------------------------------

select [TrafficDirection] , [Seized] , [Answered] , [UnRoundedCallDuration], 
       [ChargeDuration], [Amount] , [Rate]
from tb_DashboardFinancial
order by TrafficDirection


---------------------------------------------------------
-- Dashboard 3 : Top 10 Carrier Code for Terminating
-- Revenue in Last 30 Days 
---------------------------------------------------------

select [CarrierCode], [Answered], [Seized],
       [ASR], [OriginalMinutes], [ChargeMinutes],
       [Revenue], [RPM]
from tb_DashboardTerminatingRevenueByCarrierCode
order by OriginalMinutes Desc , Revenue Desc


----------------------------------------------------------------
-- Dashboard 4 : Top 10 Carrier Code and Country for Originating
-- Cost in Last 30 Days 
----------------------------------------------------------------

select [CarrierCode], [Country] ,[Answered], [Seized],
       [ASR], [OriginalMinutes], [ChargeMinutes],
       Cost, [CPM]
from tb_DashboardOrigCostByCarrierCodeAndCountry
order by OriginalMinutes Desc , Cost Desc


----------------------------------------------------------
-- Dashboard 5 : Hourly QOS Trend for Current Date 
----------------------------------------------------------

select [CallHour], [ASR] , [TotalMinutes], [MHT], [ALOC]
from tb_DashboardHourlyQOS
order by [CallHour]


----------------------------------------------------------
-- Dashboard 6 : Current Month CDR Error Summary
----------------------------------------------------------

select [ErrorType], [Direction], [MinCallDate], 
       [MaxCallDate], [Answered], [Seized],
       [CallDuration]
from tb_DashboardCDRErrorSummary
order by [Direction], [ErrorType]


----------------------------------------------------------
-- Dashboard 7 : Traffic And Margin Analysis Summary
----------------------------------------------------------

select [TrafficMonth] , [Minutes] , [Revenue] , [Cost] , [Margin]
from tb_DashboardTrafficAndMarginAnalysis
order by TrafficMonthNum 

GO
