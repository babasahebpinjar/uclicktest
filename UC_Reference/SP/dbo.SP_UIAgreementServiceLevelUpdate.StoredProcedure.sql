USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIAgreementServiceLevelUpdate]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIAgreementServiceLevelUpdate]
(
    @AgreementSLID int,
	@AgreementID int,
	@TrunkID int,
	@DirectionID int ,
	@DestinationID int,
	@ServiceLevelID int,
	@BeginDate DateTime,
	@EndDate DateTime,
	@UserID int,
	@ErrorDescription varchar(2000) Output,
    @ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

------------------------------------------------------------
-- Check to ensure the validity of all the input parameters
------------------------------------------------------------

if (@AgreementSLID is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Agreement SLA ID cannot be NULL'
	set @ResultFlag = 1
	return 1

End


if (@AgreementID is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Agreement ID cannot be NULL'
	set @ResultFlag = 1
	return 1

End

if (@TrunkID is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Trunk ID cannot be NULL'
	set @ResultFlag = 1
	return 1

End

if (@ServiceLevelID is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Service Level ID cannot be NULL'
	set @ResultFlag = 1
	return 1

End

if (@DirectionID is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Direction ID cannot be NULL'
	set @ResultFlag = 1
	return 1

End


------------------------------------------------------
-- Begin Date and End Dates should be valid values
------------------------------------------------------

If ( ( @EndDate is not NULL ) and (@BeginDate >= @EndDate) )
Begin

	set @ErrorDescription = 'ERROR !!! Begin Date cannot be greater than or equal to End Date'
	set @ResultFlag = 1
	Return 1


End

if not exists ( select 1 from tb_agreementSL where agreementSLID = @AgreementSLID and flag & 1 <> 1)
Begin

	set @ErrorDescription = 'ERROR !!! Not a valid Agreement SLA passed as input. Agreement SLA does not exist'
	set @ResultFlag = 1
	Return 1


End

if not exists ( select 1 from tb_agreement where agreementID = @AgreementID and flag & 1 <> 1)
Begin

	set @ErrorDescription = 'ERROR !!! Not a valid Agreement passed as input. Agreement does not exist'
	set @ResultFlag = 1
	Return 1


End


if not exists ( select 1 from tb_trunk where trunkID = @TrunkID and TrunkTypeID = 9 and flag & 1 <> 1)
Begin

	set @ErrorDescription = 'ERROR !!! Not a valid commercial trunk passed as input. Trunk does not exist'
	set @ResultFlag = 1
	Return 1


End


if not exists ( select 1 from tb_ServiceLevel where ServiceLevelID = @ServiceLevelID and flag & 1 <> 1)
Begin

	set @ErrorDescription = 'ERROR !!! Not a valid Service Level passed as input. Service Level does not exist'
	set @ResultFlag = 1
	Return 1


End

if ( @DestinationID is not NULL )
Begin

		if not exists ( select 1 from tb_Destination where DestinationID = @DestinationID and numberplanid = -1 and flag & 1 <> 1)
		Begin

			set @ErrorDescription = 'ERROR !!! Not a valid Destination ID passed as input. Destination ID does not exist'
			set @ResultFlag = 1
			Return 1


		End

End


------------------------------------------------------------
-- Only Inbound Direction is allowed for creation of SLA
------------------------------------------------------------

if (@DirectionID <> 1)
Begin

	set @ErrorDescription = 'ERROR !!! Service Level Assignment can only be created for INBOUND direction'
	set @ResultFlag = 1
	Return 1


End

------------------------------------------------------------------------
-- Check that the date range for the new SLA should be within the date
-- range of agreement being active
------------------------------------------------------------------------

Declare @AgreementBeginDate datetime,
        @AgreementEndDate datetime

select @AgreementBeginDate = BeginDate,
       @AgreementEndDate = EndDate
From tb_Agreement
where AgreementId = @AgreementID

if ( @BeginDate <  @AgreementBeginDate )
Begin

	set @ErrorDescription = 'ERROR !!! Agreement SLA cannot begin before the Agreement'
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

					set @ErrorDescription = 'ERROR !!! Agreement is ending on : ( ' + convert(varchar(10) , @AgreementEndDate, 120) + ' ) , but SLA is active infinitely' 
					set @ResultFlag = 1
					Return 1

			End -- End Loop 2

			Else -- Loop 3
			Begin

			        -----------------------------------------------------------------
					 -- Agreement has ended, but the POI is still active infinitely
					 ----------------------------------------------------------------

					if ( @EndDate is NULL ) -- Loop 4
					Begin 

							set @ErrorDescription = 'ERROR !!! Agreement is ending on : ( ' + convert(varchar(10) , @AgreementEndDate, 120) + ' ) , but SLA is active infinitely' 
							set @ResultFlag = 1
							Return 1

					End -- End Loop 4

					Else -- Loop 5
					Begin

							-----------------------------------------------
							 -- Agreement has ended before the POI end date
							 ----------------------------------------------

							if ( @EndDate > @AgreementEndDate ) -- Loop 6
							Begin

									set @ErrorDescription = 'ERROR !!! Agreement is ending on : ( ' + convert(varchar(10) , @AgreementEndDate, 120) + ' ) , but SLA is ending later on ( ' + convert(varchar(10) , @EndDate, 120) + ' )'
									set @ResultFlag = 1
									Return 1

							End -- End Loop 6
							
					End -- End Loop 5

			End -- End Loop 3

	End -- End Loop 1

End

--------------------------------------------------------------
-- Ensure that the new agreement SLA does not cause any kind
-- of overlaps of dates
--------------------------------------------------------------

Declare @ResultFlag2 int = 0

create table #TempDateOverlapCheck
(
	BeginDate datetime,
	EndDate datetime
)

insert into #TempDateOverlapCheck
select BeginDate , EndDate
from tb_AgreementSL
where agreementID = @AgreementID
and TrunkID = @TrunkID
and ServiceLevelID = @ServiceLevelID
and isnull(DestinationID , 0) = 
		Case 
				When @DestinationID is NULL then 0
				Else @DestinationID
		End
and AgreementSLID <> @AgreementSLID -- Exclude the agreement SLA which is being updated

Exec SP_BSCheckDateOverlap @BeginDate , @EndDate , @ResultFlag2 Output 

if (@ResultFlag2 <> 0)
Begin

	set @ErrorDescription = 'ERROR !!! Overlapping record exists for the date period and commercial trunk'
	set @ResultFlag = 1
	Drop table #TempDateOverlapCheck
	Return 1


End

Drop table #TempDateOverlapCheck

------------------------------------------------------
-- Insert record into database for new Service Level
-- Agreement
------------------------------------------------------

Begin Try


    update tb_AgreementSL
	set AgreementID = @AgreementID,
		DestinationID = @DestinationID,
		DirectionID = @DirectionID,
		ServiceLevelID = @ServiceLevelID,
		TrunkID = @TrunkID,
		BeginDate = @BeginDate,
		EndDate = @EndDate,
		ModifiedDate = Getdate(),
		ModifiedByID = @UserID	
    where AgreementSLID = @AgreementSLID


End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!! While updating record for SLA. ' + ERROR_MESSAGE()
	set @ResultFlag = 1
	return 1

End Catch

Return 0



GO
