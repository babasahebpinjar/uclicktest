USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UITechnicalTrunkDetailUpdate]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_UITechnicalTrunkDetailUpdate]
(
    @TrunkDetailID int,
	@TrunkID	int,
	@EffectiveDate	datetime,
	@ActivatedPorts	int,
	@AvailablePorts	int,
	@ProcessCode	char = NULL,
	@TargetUsage	int = NULL,
	@ActiveStatusID	int,
	@CommercialTrunkID	int,
	@DirectionID	int,
	@UserID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
AS

set @ErrorDescription = NULL
set @ResultFlag = 0

-------------------------------------------------------------
-- Check to ensure that TRUNKDETAILID is not NULL and indeed
-- a valid ID
-------------------------------------------------------------

if (@TrunkDetailID is NULL)
Begin

		set @ErrorDescription = 'ERROR !!! Trunk Detail ID cannot be NULL'
		set @ResultFlag = 1
		return 1 

End

if not exists ( select 1 from tb_trunkdetail where TrunKDetailID = @TrunkDetailID )
Begin

		set @ErrorDescription = 'ERROR !!! Technical trunk does not exist in the system for the respective ID '
		set @ResultFlag = 1
		return 1 

End

---------------------------------------------------------
-- Check to ensure that TRUNKID is not NULL and indeed
-- a valid ID
---------------------------------------------------------

Declare @OldTrunkID int

if (@TrunkID is NULL)
Begin

		set @ErrorDescription = 'ERROR !!! Trunk ID cannot be NULL'
		set @ResultFlag = 1
		return 1 

End

if not exists ( select 1 from tb_trunk where trunkID = @TrunkID )
Begin

		set @ErrorDescription = 'ERROR !!! Technical trunk does not exist in the system for the respective ID '
		set @ResultFlag = 1
		return 1 

End

select @OldTrunkID = TrunkID
from tb_TrunkDetail
where trunkdetailId = @TrunkDetailID

if ( @OldTrunkID <> @TrunkID )
Begin

		set @ErrorDescription = 'ERROR !!! ID of technical trunk associated with the trunk attribute : (' + convert(varchar(10) , @OldTrunkID) + ') is different from value : ( ' + convert(varchar(10) , @TrunkID) + ') passed in input '
		set @ResultFlag = 1
		return 1 

End

----------------------------------------------------------
-- Check Direction should not be NULL for
-- any kind of Technical Trunk
----------------------------------------------------------

if ( @DirectionID is NULL )
Begin

		set @ErrorDescription = 'ERROR !!! Technical Trunk direction cannot be NULL. It should be either Inbound , Outbound or Bidirectional'
		set @ResultFlag = 1
		return 1 

End


-------------------------------------
-- Check if EffectiveDate is NULL
-------------------------------------

if ( @EffectiveDate is NULL )
Begin

		set @ErrorDescription = 'ERROR !!! Effective Date for new Trunk Detail cannot be NULL'
		set @ResultFlag = 1
		return 1 

End


----------------------------------------------
-- Check status is a valid from the active
-- status table
----------------------------------------------

if not exists ( select 1 from tb_ActiveStatus where ActiveStatusID = @ActiveStatusID )
Begin

		set @ErrorDescription = 'ERROR !!! Status for trunk detail is not valid '
		set @ResultFlag = 1
		return 1 


End


----------------------------------------------------------------------
-- Technical trunk should have a valid Commercial trunk assigned to it
----------------------------------------------------------------------

Declare @AccountID int

select @AccountID = AccountID
from tb_trunk
where trunkID = @TrunkID

if ( 
		( @CommercialTrunkID is not NULL ) 
		and
		not exists ( select 1 from tb_trunk where trunkid = @CommercialTrunkID and trunktypeid = 9 and accountID = @AccountID )
   )
Begin

		set @ErrorDescription = 'ERROR !!! Commercial trunk assigned to technical trunk does not exist or not belong to the same account as technical trunk'
		set @ResultFlag = 1
		return 1 

End

---------------------------------------------------------------------------------
-- In case the commercial trunk is not NULL , then we need to ensure that the
-- Commercial Trunk instance existed in the system on or before the passed
-- effective date
---------------------------------------------------------------------------------

Declare @CommercialTrunk varchar(60)

select @CommercialTrunk = Trunk
from tb_trunk 
where trunkid = @CommercialTrunkID 
and trunktypeid = 9 
and accountID = @AccountID

if ( @CommercialTrunkID is not NULL )
Begin

	if not exists ( 
					select 1 
					from tb_trunkdetail 
					where trunkID = @CommercialTrunkID 
					and effectivedate <= @EffectiveDate 
				  )
	Begin

		set @ErrorDescription = 'ERROR !!! Commercial trunk : ( ' + @CommercialTrunk + ' ) is not effective in the system on or before effective date : ( ' + convert(varchar(10) , @EffectiveDate , 120) + ' )'
		set @ResultFlag = 1
		return 1 

	End

End


----------------------------------------------------------------------
-- Number of available or Activated ports should not be less than zero
-----------------------------------------------------------------------

set @ActivatedPorts = isnull(@ActivatedPorts , 0)
set @AvailablePorts = isnull(@AvailablePorts , 0)

if ( @ActivatedPorts < 0 or  @AvailablePorts < 0)
Begin

		set @ErrorDescription = 'ERROR !!! Number of Available or Active ports cannot be less than zero '
		set @ResultFlag = 1
		return 1 


End

-----------------------------------------------------------
-- Number of Active ports should not be more than number of
-- available ports
-----------------------------------------------------------

 if ( @ActivatedPorts > @AvailablePorts )
 Begin

		set @ErrorDescription = 'ERROR !!! Number of active ports cannot be greater than number of available ports '
		set @ResultFlag = 1
		return 1 

End



----------------------------------------------------------------
-- Check if there already exists a trunk detail record in the
-- system for the provided attributes
----------------------------------------------------------------

if exists ( 
			select 1 from tb_trunkdetail
			where TrunkID = @TrunkID
			and EffectiveDate = @EffectiveDate
			and ActivatedPorts = @ActivatedPorts
			and AvailablePorts = @AvailablePorts
			and CommercialTrunkID = @CommercialTrunkID
			and TargetUsage = isnull(@TargetUsage , 0)
			and DirectionID = @DirectionID
			and ActiveStatusID = @ActiveStatusID
			and TrunKDetailID <> @TrunkDetailID
		   )
Begin

		set @ErrorDescription = 'ERROR !!! Duplicate trunk detail record. Entry already exists for the new attributes'
		set @ResultFlag = 1
		return 1 

End


-------------------------------------------------------------------
-- Check if the same attributes exist for the effective date record
-- greater or lesser to the effective date of new trunk detail
-------------------------------------------------------------------

if exists ( 
			select 1 from tb_trunkdetail
			where TrunKDetailID <> @TrunkDetailID 
			and TrunkID = @TrunkID
			and ActivatedPorts = @ActivatedPorts
			and AvailablePorts = @AvailablePorts
			and CommercialTrunkID = @CommercialTrunkID
			and isnull(TargetUsage, -999) = isnull(@TargetUsage , -999)
			and DirectionID = @DirectionID
			and ActiveStatusID = @ActiveStatusID
			and EffectiveDate = 
			      (
				      select min(EffectiveDate)
					  from tb_trunkdetail
					  where trunkID = @TrunkID
					  and EffectiveDate > @EffectiveDate
				  )
		   )
Begin

		set @ErrorDescription = 'ERROR !!! Immediate future trunk detail record already exists for the new update attributes'
		set @ResultFlag = 1
		return 1 

End

if exists ( 
			select 1 from tb_trunkdetail
			where TrunKDetailID <> @TrunkDetailID
			and TrunkID = @TrunkID
			and ActivatedPorts = @ActivatedPorts
			and AvailablePorts = @AvailablePorts
			and CommercialTrunkID = @CommercialTrunkID
			and isnull(TargetUsage, -999) = isnull(@TargetUsage , -999)
			and DirectionID = @DirectionID
			and ActiveStatusID = @ActiveStatusID
			and EffectiveDate = 
			      (
				      select Max(EffectiveDate)
					  from tb_trunkdetail
					  where trunkID = @TrunkID
					  and EffectiveDate < @EffectiveDate
				  )
		   )
Begin

		set @ErrorDescription = 'ERROR !!! Immediate historical trunk detail record already exists for the new update attributes'
		set @ResultFlag = 1
		return 1 

End


------------------------------------------------------------------
-- Check to ensure that the new update to trunk detail record does
-- not cause any duplicate scenario for the CDR Match and
-- switch
------------------------------------------------------------------

Declare @CDRMatch varchar(30),
		@SwitchId int,
        @ResultFlag2 int = 0

Select @CDRMatch = CDRMatch,
	   @SwitchID = SwitchID
from tb_trunk
where TrunkID = @TrunkID

Exec SP_BSCheckOverlappingActiveTrunksOnAttributeUpdate @CDRMatch , @SwitchID , @EffectiveDate , @ActiveStatusID , @TrunkID , @TrunkDetailId,  @ResultFlag2 output

if ( @ResultFlag2 = 1 )
Begin

		set @ErrorDescription = 'ERROR !!! Trunk detail update causes overlapping records for the CDRMatch : ' + @CDRMatch + ' in the system'
		set @ResultFlag = 1
		return 1 	

End

--------------------------------------------------
-- Update the trunk detail record in the system
--------------------------------------------------

update tb_TrunkDetail
set EffectiveDate = @EffectiveDate,
	ActivatedPorts = @ActivatedPorts,
	AvailablePorts = @AvailablePorts,
	ProcessCode = @ProcessCode,
	TargetUsage = @TargetUsage,
	TrunkID = @TrunkID,
	ActiveStatusID = @ActiveStatusID,
	CommercialTrunkID = @CommercialTrunkID,
	DirectionID = @DirectionID,
	ModifiedDate = getdate(),
	ModifiedByID = @UserID,
	Flag = 0
where TrunkDetailID = @TrunkDetailID

Return 0





GO
