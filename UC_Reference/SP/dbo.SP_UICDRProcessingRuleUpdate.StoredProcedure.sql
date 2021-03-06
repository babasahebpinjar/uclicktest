USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICDRProcessingRuleUpdate]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[SP_UICDRProcessingRuleUpdate]
(
    @CDRprocessingRuleID int,
    @RuleOrder int,
	@TrunkID int ,
	@PrefixCode varchar(100),
	@ServiceLevelID int,
	@DirectionID int,
	@BeginDate datetime,
	@EndDate datetime,
	@UserID int,
	@ErrorDescription varchar(2000) output,
	@ResultFlag int output
)
As


set @ErrorDescription = NULL
set @ResultFlag = 0

------------------------------------------------
-- Check if CDR Processing Rule is NULL or not
------------------------------------------------

if (@CDRprocessingRuleID is NULL)
Begin

	set @ErrorDescription = 'ERROR !!! CDR processing Rule ID cannot be NULL'
	set @ResultFlag = 1
	return 1

End

------------------------------------------------------
-- Check if Processing Rule  exists in system or not
------------------------------------------------------

if not exists (select 1 from tb_CDRProcessingRule where CDRProcessingRuleID = @CDRprocessingRuleID )
Begin

	set @ErrorDescription = 'ERROR !!! No CDR Processing Rule exists in the system for the passed ID'
	set @ResultFlag = 1
	return 1

End

---------------------------------------
-- Check if TRUNKID is NULL or not
---------------------------------------

if (@TrunkID is NULL)
Begin

	set @ErrorDescription = 'ERROR !!! Trunk ID cannot be NULL'
	set @ResultFlag = 1
	return 1

End

--------------------------------------------
-- Check if trunk exists in system or not
--------------------------------------------

Declare @ConfigValue varchar(1000)

Select @ConfigValue = ConfigValue
from UC_Admin.dbo.tb_Config
where ConfigName = 'CDRPrefixingLevel'
and AccessScopeID = -4

set @ConfigValue = isnull(@ConfigValue,0)

if (@ConfigValue = 1)
Begin

		if not exists (select 1 from tb_trunk where trunkID = @TrunkID and TrunkTypeID = 9 )
		Begin

			set @ErrorDescription = 'ERROR !!! No Commercial trunk exists in the system for the TRUNKID'
			set @ResultFlag = 1
			return 1

		End

End

Else
Begin

		if not exists (select 1 from tb_trunk where trunkID = @TrunkID and TrunkTypeID <> 9 )
		Begin

			set @ErrorDescription = 'ERROR !!! No physical or technical trunk exists in the system for the TRUNKID'
			set @ResultFlag = 1
			return 1

		End

End


---------------------------------------------------------------
-- Make sure that Rule Order is a number greater than 0
---------------------------------------------------------------

if( (ISNUMERIC(@RuleOrder) = 0 ) or (@RuleOrder <= 0))
Begin

	set @ErrorDescription = 'ERROR !!! Rule order has to be a numeric value greater than 0'
	set @ResultFlag = 1
	return 1

End

-------------------------------------------------------------------
-- Ensure that the Direction of the Service Level and Direction
-- of CDR Processing rule are the same and Service Level exists
-- in the system
-------------------------------------------------------------------

if not exists (select 1 from tb_ServiceLevel where ServiceLevelID = @ServiceLevelID and DirectionID = @DirectionID )
Begin

	set @ErrorDescription = 'ERROR !!! No Service Level exists in the system for the SERVICELEVELID and DIRECTIONID '
	set @ResultFlag = 1
	return 1

End

--------------------------------------------------------------------
-- Make sure that the begin date is lesser than equal to End Date
--------------------------------------------------------------------

if( ( @EndDate is not NULL ) and ( @BeginDate >= @EndDate) )
Begin

	set @ErrorDescription = 'ERROR !!! Begin Date cannot be greater than or equal to the End Date'
	set @ResultFlag = 1
	return 1

End

------------------------------------------------------------------
-- Ensure that the Rule Order is a unique number not being used
-- by other CDR processing Rules
------------------------------------------------------------------

Declare @DateOverlapCheckFlag int = 0

create table #TempDateOverlapCheck 
(
	CDRprocessingRuleID int,
	BeginDate datetime,
	EndDate datetime
)

insert into #TempDateOverlapCheck
select CDRprocessingRuleID , Begindate , EndDate
from tb_CDRProcessingRule
where RuleOrder = @RuleOrder
and trunkID = @TrunkID
and DirectionID = @DirectionID
and CDRProcessingRuleID <> @CDRprocessingRuleID

Exec  SP_BSCheckDateOverlap @BeginDate , @EndDate , @DateOverlapCheckFlag output

if ( @DateOverlapCheckFlag = 1 )
Begin

	set @ErrorDescription = 'ERROR !!! There exist Rule(s) in the system for Trunk and Direction, having same Rule Order as the new processing rule'
	set @ResultFlag = 1
	drop table #TempDateOverlapCheck
	return 1

End


-----------------------------------------------------------------
-- Check to see that there are no overlapping rules in the 
-- system for the combination of:
-- Prefix , ServiceLEvelID , TrunkID , DirectionID
-----------------------------------------------------------------

set @DateOverlapCheckFlag = 0

Delete from #TempDateOverlapCheck

insert into #TempDateOverlapCheck
select CDRprocessingRuleID , Begindate , EndDate
from tb_CDRProcessingRule
where ServiceLevelID = @ServiceLevelID
and TrunkID = @TrunkID
and DirectionID in ( @DirectionID , 3)
and isNULL(PrefixCode, 'Empty') = isNULL(@PrefixCode , 'Empty')
and CDRProcessingRuleID <> @CDRprocessingRuleID

Exec  SP_BSCheckDateOverlap @BeginDate , @EndDate , @DateOverlapCheckFlag output

if ( @DateOverlapCheckFlag = 1 )
Begin

	set @ErrorDescription = 'ERROR !!! There exist Rule(s) in the system having dates overlapping with the new processing rule for combination of Trunk , Direction , Service Level and Prefix Code'
	set @ResultFlag = 1
	drop table #TempDateOverlapCheck
	return 1

End

drop table #TempDateOverlapCheck

--------------------------------------------------------------
-- Update record into the database for the new Processing Rule
--------------------------------------------------------------

Begin Try

	update tb_CDRProcessingRule
	set RuleOrder = @RuleOrder,
	    PrefixCode = @PrefixCode,
        ServiceLevelID = @ServiceLevelID,
		TrunkID = @TrunkID,
		DirectionID = @DirectionID,
		BeginDate = @BeginDate,
		EndDate = @EndDate,
		ModifiedDate = getdate(),
		ModifiedByID = @UserID
	where CDRProcessingRuleID = @CDRprocessingRuleID

End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!! During update of CDR Processing Rule record.' + ERROR_MESSAGE()
	set @ResultFlag = 1
	return 1

End Catch


GO
