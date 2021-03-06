USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRatingScenarioHubbingUpdate]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRatingScenarioHubbingUpdate]
(
    @RatingScenarioID int,
	@AgreementID int,
	@CommercialTrunkID int,
	@CallTypeID int,
	@CountryID int,
	@DirectionID int,
	@ServiceLevelID int,
	@BeginDate Date,
	@EndDate Date,
	@RatingScenarioName varchar(100),
	@RatingScenarioDescription varchar(200),
	@UserID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

-- Attribute1 = Agreement
-- Attribute2 = Commercial Trunk
-- Attribute3 = Call Type
-- Attribute4 = Country
-- Attribute5 = Direction

set @ErrorDescription = NULL
set @ResultFlag = 0

if ( @CountryID = 0 )
	Set @CountryID = NULL -- This means all the Countries

if ( @ServiceLevelID = 0 )
	Set @ServiceLevelID = NULL -- This means all the Service Levels

----------------------------------------------------------------------
-- Check Validity of all the input parameters to ensure data integrity
----------------------------------------------------------------------

if ( @RatingScenarioID is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Rating Scenario ID cannot be NULL'
	set @ResultFlag = 1
	Return 1

End

if ( @AgreementID is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Agreement ID cannot be NULL'
	set @ResultFlag = 1
	Return 1

End

if ( @CallTypeID is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Call Type ID cannot be NULL'
	set @ResultFlag = 1
	Return 1

End

if ( @CommercialTrunkID is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Commercial Trunk ID cannot be NULL'
	set @ResultFlag = 1
	Return 1

End

if ( @DirectionID is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Direction ID cannot be NULL'
	set @ResultFlag = 1
	Return 1

End

if ( @BeginDate is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Begin Date cannot be NULL'
	set @ResultFlag = 1
	Return 1

End

----------------------------------
-- Check the validy of the Dates
----------------------------------

if ( ( @EndDate is not NULL ) and ( @BeginDate >= @EndDate ) )
Begin

	set @ErrorDescription = 'ERROR !!! Begin Date cannot be greate than or equal to End Date'
	set @ResultFlag = 1
	Return 1

End


---------------------------------------------------------------
-- Ensure that all input parameters are valid IDs existing in
-- the system
---------------------------------------------------------------

if not exists ( Select 1 from tb_RatingScenario where RatingScenarioID = @RatingScenarioID )
Begin

	set @ErrorDescription = 'ERROR !!! Rating Scenario ID is not valid and does not exist in the system'
	set @ResultFlag = 1
	Return 1

End

if not exists ( select 1 from tb_Agreement where AgreementID = @AgreementID )
Begin

	set @ErrorDescription = 'ERROR !!! Agreement ID not valid and does not exist in system'
	set @ResultFlag = 1
	Return 1

End

if not exists ( select 1 from tb_CallType where calltypeID = @CallTypeID )
Begin

	set @ErrorDescription = 'ERROR !!! Call Type ID not valid and does not exist in system'
	set @ResultFlag = 1
	Return 1

End

if not exists ( select 1 from tb_trunk where trunkID = @CommercialTrunkID and trunktypeID = 9 )
Begin

	set @ErrorDescription = 'ERROR !!! Commercial Trunk ID not valid and does not exist in system'
	set @ResultFlag = 1
	Return 1

End

if ( @DirectionID not in (1,2) )
Begin

	set @ErrorDescription = 'ERROR !!! Direction has to be either Inbound or Outbound '
	set @ResultFlag = 1
	Return 1

End

if  (
       	 ( @ServiceLevelID is not NULL )
	 and
        not exists ( select 1 from tb_ServiceLevel where ServiceLevelID = @ServiceLevelID and DirectionID = @DirectionID )
    )
Begin

	set @ErrorDescription =  'ERROR !!! ServiceLevel ID not valid and does not exist in system or is not valid for the Direction'
	set @ResultFlag = 1
	Return 1

End


if (
	 ( @CountryID is not NULL )
	 and
     ( not exists ( select 1 from tb_country where countryID = @CountryID ) )
   )
Begin

	set @ErrorDescription = 'ERROR !!! Country ID not valid and does not exist in system'
	set @ResultFlag = 1
	Return 1

End

---------------------------------------------------------
-- Check to ensure that the Call Type , Direction and
-- Charge Type are in match
---------------------------------------------------------
Declare @ChargeBasisID int

Select @ChargeBasisID = ChargeBasisID
from tb_CallType
where CallTypeID = @CallTypeID


if exists ( select 1 from tb_RatingSettlement where ratingScenarioID = @RatingScenarioID )
Begin

    ------------------------------------------------------------------------------
    -- Inbound Direction with Forward Charging should have Charge Type as Revenue
	------------------------------------------------------------------------------

	if (
	      ( @DirectionID = 1 and @ChargeBasisID =  -1 ) 
		  and exists 
		  ( Select 1 from tb_RatingSettlement where ratingScenarioID = @RatingScenarioID and ChargetypeID <> -2)
	   )
	Begin

		set @ErrorDescription = 'ERROR !!! Rating Scenario for INBOUND Direction with FORWARD Charging should have settlement as REVENUE'
		set @ResultFlag = 1
		Return 1

	End

    ------------------------------------------------------------------------------
    -- Inbound Direction with Reverse Charging should have Charge Type as Cost
	------------------------------------------------------------------------------

	if (
	      ( @DirectionID = 1 and @ChargeBasisID =  -2 ) 
		  and exists 
		  ( Select 1 from tb_RatingSettlement where ratingScenarioID = @RatingScenarioID and ChargetypeID <> -1)
	   )
	Begin

		set @ErrorDescription = 'ERROR !!! Rating Scenario for INBOUND Direction with REVERSE Charging should have settlement as COST'
		set @ResultFlag = 1
		Return 1

	End

    ------------------------------------------------------------------------------
    -- Outbound Direction with Forward Charging should have Charge Type as Cost
	------------------------------------------------------------------------------

	if (
	      ( @DirectionID = 2 and @ChargeBasisID =  -1 ) 
		  and exists 
		  ( Select 1 from tb_RatingSettlement where ratingScenarioID = @RatingScenarioID and ChargetypeID <> -1)
	   )
	Begin

		set @ErrorDescription = 'ERROR !!! Rating Scenario for OUTBOUND Direction with FORWARD Charging should have settlement as COST'
		set @ResultFlag = 1
		Return 1

	End

    ------------------------------------------------------------------------------
    -- Outbound Direction with Reverse Charging should have Charge Type as REVENUE
	------------------------------------------------------------------------------

	if (
	      ( @DirectionID = 2 and @ChargeBasisID =  -2 ) 
		  and exists 
		  ( Select 1 from tb_RatingSettlement where ratingScenarioID = @RatingScenarioID and ChargetypeID <> -2)
	   )
	Begin

		set @ErrorDescription = 'ERROR !!! Rating Scenario for OUTBOUND Direction with REVERSE Charging should have settlement as REVENUE'
		set @ResultFlag = 1
		Return 1

	End

End

--------------------------------------------------------------
-- Check to ensure that Agreement and Commercial Trunk belong
-- to the same Account
--------------------------------------------------------------

Declare @AgreementAccountID int,
        @CommercialTrunkAccountID int

select @AgreementAccountID = AccountID
from tb_Agreement
where agreementID = @AgreementID

select @CommercialTrunkAccountID = AccountID
from tb_Trunk
where TrunkID = @CommercialTrunkID

if ( @AgreementAccountID <> @CommercialTrunkAccountID ) 
Begin

	set @ErrorDescription = 'ERROR !!! Commercial Trunk and Agreement do not belong to the same account'
	set @ResultFlag = 1
	Return 1

End

------------------------------------------------------------------------
-- Check that the date range for the new Rating Scenario should be within 
-- the date range of agreement being active
------------------------------------------------------------------------

Declare @AgreementBeginDate datetime,
        @AgreementEndDate datetime

select @AgreementBeginDate = BeginDate,
       @AgreementEndDate = EndDate
From tb_Agreement
where AgreementId = @AgreementID

if ( @BeginDate <  @AgreementBeginDate )
Begin

	set @ErrorDescription = 'ERROR !!! Rating Scenario cannot begin before the Agreement'
	set @ResultFlag = 1
	Return 1


End

Else
Begin

	if ( @AgreementEndDate is not NULL ) -- Loop 1
	Begin
	        ---------------------------------------------------------------
	 		-- Agreement has ended, but the SLA is still active infinitely
			---------------------------------------------------------------

			if ( @EndDate is NULL ) -- Loop 2 
			Begin

					set @ErrorDescription = 'ERROR !!! Agreement is ending on : ( ' + convert(varchar(10) , @AgreementEndDate , 120) + ' ) , but Rating Scenario is active infinitely' 
					set @ResultFlag = 1
					Return 1

			End -- End Loop 2

			Else -- Loop 3
			Begin

			        -----------------------------------------------------------------
					 -- Agreement has ended, but the SLA is still active infinitely
					 ----------------------------------------------------------------

					if ( @EndDate is NULL ) -- Loop 4
					Begin 

							set @ErrorDescription = 'ERROR !!! Agreement is ending on : ( ' + convert(varchar(10) , @AgreementEndDate, 120) + ' ) , but Rating Scenario is active infinitely' 
							set @ResultFlag = 1
							Return 1

					End -- End Loop 4

					Else -- Loop 5
					Begin

							-----------------------------------------------
							 -- Agreement has ended before the SLA end date
							 ----------------------------------------------

							if ( @EndDate > @AgreementEndDate ) -- Loop 6
							Begin

									set @ErrorDescription = 'ERROR !!! Agreement is ending on : ( ' + convert(varchar(10) , @AgreementEndDate, 120) + ' ) , but Rating Scenario is ending later on ( ' + convert(varchar(10) , @EndDate, 120) + ' )'
									set @ResultFlag = 1
									Return 1

							End -- End Loop 6
							
					End -- End Loop 5

			End -- End Loop 3

	End -- End Loop 1

End

---------------------------------------------------------------
-- Check to ensure that the rating scenario does not overlap
-- with any other rating scenario
---------------------------------------------------------------

Declare @ResultFlag2 int = 0

create table #TempDateOverlapCheck
(
	BeginDate datetime,
	EndDate datetime
)

insert into #TempDateOverlapCheck
select BeginDate , EndDate
from tb_RatingScenario
where Attribute1ID = @AgreementID
and Attribute2ID = @CommercialTrunkID
and Attribute3ID = @CallTypeID
and isnull(Attribute4ID, 0) = 
			Case
				When nullif(@CountryID, 0) is NULL Then 0
				Else @CountryID
			End
and Attribute5ID = @DirectionID
and isnull(Attribute6ID,0) =  isnull(@ServiceLevelID,0)
and RatingScenarioID <> @RatingScenarioID -- Exclude the rating scenario which is being updated

Exec SP_BSCheckDateOverlap @BeginDate , @EndDate , @ResultFlag2 Output 

if (@ResultFlag2 <> 0)
Begin

	set @ErrorDescription = 'ERROR !!! Overlapping rating scenario record(s) exist for the date period '
	set @ResultFlag = 1
	Drop table #TempDateOverlapCheck
	Return 1


End

Drop table #TempDateOverlapCheck

---------------------------------------------------------------
-- Update record in database for the Rating Scenario
---------------------------------------------------------------

Begin Try

    Update tb_RatingScenario
	set RatingScenarioName = ltrim(Rtrim(@RatingScenarioName)),
		RatingScenarioDescription = ltrim(Rtrim(@RatingScenarioDescription)),
		Attribute1ID = @AgreementID,
		Attribute2ID = @CommercialTrunkID,
		Attribute3ID = @CallTypeID,
		Attribute4ID = @CountryID,
		Attribute5ID = @DirectionID,
		Attribute6ID = @ServiceLevelID,
		BeginDate = @BeginDate,
		EndDate = @EndDate,
		ModifiedDate = GetDate(),
		ModifiedByID = @UserID
	where RatingScenarioID = @RatingScenarioID

End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!! Updating rating scenario record.' + ERROR_MESSAGE()
	set @ResultFlag = 1
	Return 1

End Catch
GO
