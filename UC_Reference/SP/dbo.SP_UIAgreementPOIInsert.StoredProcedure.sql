USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIAgreementPOIInsert]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIAgreementPOIInsert]
(
	@AgreementID int,
	@TrunkID int,
	@DirectionID int,
	@BeginDate DateTime,
	@EndDate DateTime,
	@UserID int,
	@ErrorDescription varchar(200) Output,
	@ResultFlag int Output
)
As

set @ResultFlag = 0
set @ErrorDescription = NULL

-----------------------------------------------------------------------
-- Make sure that Agreement, Trunk and DirectionID are not NULL and 
-- valid values
-----------------------------------------------------------------------

if ( @AgreementID is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Agreement ID cannot be NULL'
	set @ResultFlag = 1
	Return 1


End


if ( @TrunkID is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Trunk ID cannot be NULL'
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

if not exists ( select 1 from tb_Direction where DirectionID = @DirectionID and flag & 1 <> 1)
Begin

	set @ErrorDescription = 'ERROR !!! Not a valid trunk direction passed as input. Direction does not exist'
	set @ResultFlag = 1
	Return 1


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

--------------------------------------------------------------
-- Ensure that the new agreement POI does not cause any kind
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
from tb_AgreementPOI
where agreementID = @AgreementID
and TrunkID = @TrunkID

Exec SP_BSCheckDateOverlap @BeginDate , @EndDate , @ResultFlag2 Output 

if (@ResultFlag2 <> 0)
Begin

	set @ErrorDescription = 'ERROR !!! Overlapping record exists for the date period and commercial trunk'
	set @ResultFlag = 1
	Drop table #TempDateOverlapCheck
	Return 1


End

Drop table #TempDateOverlapCheck


------------------------------------------------------------------------
-- Check that the date range for the new POI should be within the date
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

	set @ErrorDescription = 'ERROR !!! Agreement POI cannot begin before the Agreement'
	set @ResultFlag = 1
	Return 1


End

Else
Begin

	if ( @AgreementEndDate is not NULL ) -- Loop 1
	Begin
	        ---------------------------------------------------------------
	 		-- Agreement has ended, but the POI is still active infinitely
			---------------------------------------------------------------

			if ( @EndDate is NULL ) -- Loop 2 
			Begin

					set @ErrorDescription = 'ERROR !!! Agreement is ending on : ( ' + convert(varchar(10) , @AgreementEndDate, 120) + ' ) , but POI is active infinitely' 
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

							set @ErrorDescription = 'ERROR !!! Agreement is ending on : ( ' + convert(varchar(10) , @AgreementEndDate,120) + ' ) , but POI is active infinitely' 
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

									set @ErrorDescription = 'ERROR !!! Agreement is ending on : ( ' + convert(varchar(10) , @AgreementEndDate, 120) + ' ) , but POI is ending later on ( ' + convert(varchar(10) , @EndDate , 120) + ' )'
									set @ResultFlag = 1
									Return 1

							End -- End Loop 6
							
					End -- End Loop 5

			End -- End Loop 3

	End -- End Loop 1

End

-----------------------------------------------
-- Insert data into the tb_agreementPOI table
-----------------------------------------------

Begin Try

	Insert into tb_AgreementPOI
	(
		AgreementID,
		TrunkID,
		DirectionID,
		BeginDate,
		EndDate,
		Modifieddate,
		ModifiedByID,
		Flag
	)
	values
	(
		@AgreementID,
		@TrunkID,
		@DirectionID,
		@BeginDate,
		@EndDate,
		Getdate(),
		@UserID,
		0
	)
	
End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!! Inserting new POI record. Please check configuration'
	set @ResultFlag = 1
	Return 1

End Catch

return 0
GO
