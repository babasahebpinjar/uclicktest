USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRatingSettlementUpdate]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRatingSettlementUpdate]
(
	@RatingSettlementID int,
	@TariffTypeID int,
	@RatePlanID int,
	@Percentage int,
	@ChargeTypeID int,
	@UserID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

----------------------------------------------------------------------
-- Check Validity of all the input parameters to ensure data integrity
----------------------------------------------------------------------

if ( @RatingSettlementID is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Rating Settlement ID cannot be NULL'
	set @ResultFlag = 1
	Return 1

End


if ( @TariffTypeID is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Tariff Type ID cannot be NULL'
	set @ResultFlag = 1
	Return 1

End


if ( @RatePlanID is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Rate Plan ID cannot be NULL'
	set @ResultFlag = 1
	Return 1

End

-------------------------------------------------------
-- Percentage should be postive greater than 0 value
-------------------------------------------------------

if ( (@Percentage is NULL) or ( isnumeric(@Percentage) = 0) or ( @Percentage <= 0 ) )
Begin

	set @ErrorDescription = 'ERROR !!! Percentage cannot be NULL or less than zero. Please define a numerical greater than zero value'
	set @ResultFlag = 1
	Return 1
	
End

------------------------------------------------------------
-- Rating Settlement should be valid and exists in the system
------------------------------------------------------------

if not exists ( select 1 from tb_RatingSettlement where RatingSettlementID = @RatingSettlementID )
Begin

	set @ErrorDescription = 'ERROR !!! Rating Settlement ID not valid and does not exist in system'
	set @ResultFlag = 1
	Return 1

End

----------------------------------------------------
-- Get Details from the rating scenario record
----------------------------------------------------

Declare @AgreementID int,
		@CommercialTrunkID int,
		@CallTypeID int,
		@DirectionID int,
		@RatingScenarioID int

select 
	@AgreementID = Attribute1ID ,
	@CommercialTrunkID = Attribute2ID ,
	@CallTypeID = Attribute3ID ,
	@DirectionID = Attribute5ID,
	@RatingScenarioID = tbl1.RatingScenarioID
From tb_RatingSettlement tbl1
inner join tb_RatingScenario tbl2 on tbl1.RatingScenarioID = tbl2.RatingScenarioID
where tbl1.RatingSettlementID = @RatingSettlementID


--------------------------------------------------------------
-- Check to ensure that Agreement and Rate Plan belong
-- to the same Account
--------------------------------------------------------------
Declare @RatePlanAccountID int,
        @RatePlanDirectionID int,
		@AgreementAccountID int


if ( @RatePlanID <> -2) -- Rate Plan is not "Not Applicable"
Begin
		select @RatePlanAccountID = AccountID,
			   @RatePlanDirectionID = DirectionID
		from tb_RatePlan tbl1
		inner join tb_Agreement tbl2 on tbl1.AgreementID = tbl2.AgreementID
		where RatePlanID = @RatePlanID

		select @AgreementAccountID = AccountID
		from tb_Agreement
		where agreementID = @AgreementID

		if ( @AgreementAccountID <> @RatePlanAccountID ) 
		Begin

			set @ErrorDescription = 'ERROR !!! Rate Plan and Agreement do not belong to the same account'
			set @ResultFlag = 1
			Return 1

		End

		-----------------------------------------------------------
		-- Check to ensure that direction of Rate plan and scenario
		-- should be the same
		-----------------------------------------------------------

		if ( @RatePlanDirectionID <> @DirectionID )
		Begin

			set @ErrorDescription = 'ERROR !!! Rate Plan  direction not same as the direction of the rating scenario'
			set @ResultFlag = 1
			Return 1

		End

End

---------------------------------------------------------
-- Check to ensure that the Call Type , Direction and
-- Charge Type are in match
---------------------------------------------------------

Declare @ChargeBasisID int

Select @ChargeBasisID = ChargeBasisID
from tb_CallType
where CallTypeID = @CallTypeID

------------------------------------------------------------------------------
-- Inbound Direction with Forward Charging should have Charge Type as Revenue
------------------------------------------------------------------------------

if ( @DirectionID = 1 and @ChargeBasisID = -1  and @ChargeTypeID <> -2) 
Begin

	set @ErrorDescription = 'ERROR !!! Rating Scenario for INBOUND Direction with FORWARD Charging should have settlement as REVENUE'
	set @ResultFlag = 1
	Return 1

End

------------------------------------------------------------------------------
-- Inbound Direction with Reverse Charging should have Charge Type as Cost
------------------------------------------------------------------------------

if (@DirectionID = 1 and @ChargeBasisID = -2  and @ChargetypeID <> -1) 
Begin

	set @ErrorDescription = 'ERROR !!! Rating Scenario for INBOUND Direction with REVERSE Charging should have settlement as COST'
	set @ResultFlag = 1
	Return 1

End

------------------------------------------------------------------------------
-- Outbound Direction with Forward Charging should have Charge Type as Cost
------------------------------------------------------------------------------

if ( @DirectionID = 2 and @ChargeBasisID = -1  and @ChargeTypeID <> -1 ) 
Begin

	set @ErrorDescription = 'ERROR !!! Rating Scenario for OUTBOUND Direction with FORWARD Charging should have settlement as COST'
	set @ResultFlag = 1
	Return 1

End

------------------------------------------------------------------------------
-- Outbound Direction with Reverse Charging should have Charge Type as REVENUE
------------------------------------------------------------------------------

if ( @DirectionID = 2 and @ChargeBasisID = -2 and @ChargeTypeID <> -2 ) 
Begin

	set @ErrorDescription = 'ERROR !!! Rating Scenario for OUTBOUND Direction with REVERSE Charging should have settlement as REVENUE'
	set @ResultFlag = 1
	Return 1

End

---------------------------------------------------------------------
-- Check if duplicate rating settlement record exists in the system
---------------------------------------------------------------------

if exists (
				select 1
				from tb_RatingSettlement
				where RatingScenarioID = @RatingScenarioID
				and TariffTypeID = @TariffTypeID
				and ChargeTypeID = @ChargeTypeID
				and RatePlanID = @RatePlanID
				and RatingSettlementID <> @RatingSettlementID
		  )
Begin

	set @ErrorDescription = 'ERROR !!! Rating Settlement record already exists in the system for new update attributes'
	set @ResultFlag = 1
	Return 1

End

-------------------------------------------------------------
-- Insert record into database for the new rating settlement
-------------------------------------------------------------

Begin Try

	Update tb_RatingSettlement
	set Percentage = @Percentage,
		TariffTypeID = @TariffTypeID,
		ChargeTypeID = @ChargeTypeID,
		RatePlanId = @RatePlanID,
		ModifiedDate = Getdate(),
		ModifiedById = @UserID
	where RatingSettlementID = @RatingSettlementID

End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!! Updating settlement record for rating scenario.' + ERROR_MESSAGE()
	set @ResultFlag = 1
	Return 1

End Catch


GO
