USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_RPTCDRErrorDetailReport]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_RPTCDRErrorDetailReport]
(
	@StartDate datetime,
	@EndDate datetime,
	@ErrorTypeID int = 0, -- default Value, 0 means all error types
	@DirectionID int = 0, -- default value, 0 means all directions
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

----------------------------------------------------------------------
-- Check to ensure that Start date is less than equal to the End Date
----------------------------------------------------------------------

if (@StartDate > @EndDate)
Begin

		set @ErrorDescription = 'ERROR !!!! Start Date Should be less than equal to End Date'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End

--------------------------------------------------------------
-- Check to ensure that the ERROR TYPE value is between 0 -9
--------------------------------------------------------------

if ( @ErrorTypeID not between 0 and 9 )
Begin

		set @ErrorDescription = 'ERROR !!!! Flag for Error type should be between 0 and 9'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End

--------------------------------------------------------------
-- Check to ensure that the DIRECTION value is between 0-2
--------------------------------------------------------------

if ( @DirectionID not between 0 and 2 )
Begin

		set @ErrorDescription = 'ERROR !!!! Direction flag should be either 0 (All), 1 (Inbound) or 2 (Outbound)'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End

--------------------------------------------------------------------
-- set Error type and Direction to NULL, if the values are 0
--------------------------------------------------------------------

if ( @ErrorTypeID = 0 )
	set @ErrorTypeID = NULL

if ( @DirectionID = 0 )
	set @DirectionID = NULL

-----------------------------------------------------------------------
-- Create temporary table to store all the reference data essential
-- for running the report
-----------------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempRoutingDestination') )
		Drop table #tempRoutingDestination

Select DestinationID , Destination 
into #tempRoutingDestination
from ReferenceServer.UC_Reference.dbo.tb_Destination
where numberplanID = -1 -- Routing

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempSettlementDestination') )
		Drop table #tempSettlementDestination

Select DestinationID , Destination 
into #tempSettlementDestination
from ReferenceServer.UC_Reference.dbo.tb_Destination
where numberplanID <> -1 -- Rating

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempServiceLevel') )
		Drop table #tempServiceLevel

Select ServiceLevelID , ServiceLevel
into #tempServiceLevel
from ReferenceServer.UC_Reference.dbo.tb_ServiceLevel


if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempCallType') )
		Drop table #tempCallType

Select CallTypeID , CallType
into #tempCallType
from ReferenceServer.UC_Reference.dbo.tb_CallType


if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempTechnicalTrunk') )
		Drop table #tempTechnicalTrunk

Select TrunkID , Trunk
into #tempTechnicalTrunk
from ReferenceServer.UC_Reference.dbo.tb_Trunk
where TrunkTypeID <> 9 -- Physical Trunks


if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempCommercialTrunk') )
		Drop table #tempCommercialTrunk

Select TrunkID , Trunk
into #tempCommercialTrunk
from ReferenceServer.UC_Reference.dbo.tb_Trunk
where TrunkTypeID = 9 -- Commercial Trunk Grouping

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempRatePlan') )
		Drop table #TempRatePlan

Select RatePlanID , RatePlan
into #tempRatePlan
from ReferenceServer.UC_Reference.dbo.tb_RatePlan


if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempNumberPlan') )
		Drop table #tempNumberPlan

Select NumberPlanID , NumberPlan
into #tempNumberPlan
from ReferenceServer.UC_Reference.dbo.tb_NumberPlan

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempAccount') )
		Drop table #tempAccount

Select AccountID , Account
into #tempAccount
from ReferenceServer.UC_Reference.dbo.tb_Account

select tbl1.ErrorType as ErrorTypeID , tbl12.CDRErrorType as ErrorType,
       tbl1.DirectionID , tbl2.Direction,
       tbl1.CallDate, tbl1.Answered , tbl1.Seized , convert(decimal(19,2) , CallDuration) as CallDuration,
	   tbl1.CalledNumber , tbl1.OriginalCalledNumber,
	   tbl1.CalltypeID ,  isnull(tbl3.CallType , '****') as CallType,
	   tbl1.AccountID , isnull(tbl4.Account , '****') as Account,
	   tbl1.TrunkID ,
	   Case
			When tbl5.Trunk is NULL then 
			    Case
					When tbl1.TrunkName is NULL then '****'
					Else tbl1.TrunkName
				End 
			Else tbl5.Trunk
	   End as Trunk,	   
	   tbl1.CommercialTrunkID , isnull(tbl6.Trunk , '****') as CommercialTrunk,
	   tbl1.DestinationID , isnull(tbl7.Destination , '****') as SettlementDestination,
	   tbl1.RoutingDestinationID , isnull(tbl8.Destination , '****') as RoutingDestination,
	   tbl1.ServiceLevelID , isnull(tbl9.ServiceLevel , '****') as ServiceLevel,
	   tbl1.RatePlanID  , isnull(tbl10.RatePlan , '****') as RatePlan,
	   tbl1.NumberPlanID , isnull(tbl11.NumberPlan , '****') as NumberPlan
from tb_CDRErrorSummary tbl1
inner join ReferenceServer.UC_Reference.dbo.tb_Direction tbl2 on tbl1.DirectionID = tbl2.DirectionID
left join #tempCallType tbl3 on tbl1.CallTypeID = tbl3.CallTypeID
left join #tempAccount tbl4 on tbl1.AccountID = tbl4.AccountID
left join #tempTechnicalTrunk tbl5 on tbl1.TrunkID = tbl5.TrunkID
left join #tempCommercialTrunk tbl6 on tbl1.CommercialTrunkID = tbl6.TrunkID
left join #tempSettlementDestination  tbl7 on tbl1.DestinationId = tbl7.DestinationID
left join #tempRoutingDestination tbl8 on tbl1.RoutingDestinationId = tbl8.DestinationID
left join #tempServiceLevel tbl9 on tbl1.ServiceLevelID = tbl9.ServiceLevelID
left join #tempRatePlan tbl10 on tbl1.RatePlanID = tbl10.RatePlanID
left join #tempNumberPlan tbl11 on tbl1.NumberPlanID = tbl11.NumberPlanID
inner join tb_CDRErrorType tbl12 on tbl1.Errortype = tbl12.CDRErrorTypeID
Where CallDate between @StartDate and @EndDate
and tbl1.DirectionID = isNull(@DirectionID , tbl1.DirectionID)
and tbl1.ErrorType = isNULL(@ErrorTypeID , tbl1.ErrorType)
order by tbl2.Direction , 
         tbl1.ErrorType , 
		 tbl1.CallDate, 
		 tbl1.CallDuration Desc

ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempRoutingDestination') )
		Drop table #tempRoutingDestination

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempServiceLevel') )
		Drop table #tempServiceLevel

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempCallType') )
		Drop table #tempCallType

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempTechnicalTrunk') )
		Drop table #tempTechnicalTrunk

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempRatePlan') )
		Drop table #tempRatePlan

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempNumberPlan') )
		Drop table #tempNumberPlan

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempAccount') )
		Drop table #tempAccount
GO
