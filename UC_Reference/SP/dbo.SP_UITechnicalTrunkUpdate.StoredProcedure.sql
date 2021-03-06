USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UITechnicalTrunkUpdate]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_UITechnicalTrunkUpdate]
(
    @TrunkID int,
	@Trunk varchar(60)  ,
	@TrunkTypeID int  ,
	@SwitchID int  ,
	@TSwitchID int  = NULL ,
	@CDRMatch varchar(30)  ,
	@AccountID int  ,
	@EffectiveDate datetime  ,
	@ActivatedPorts int  ,
	@AvailablePorts int  = NULL ,
	@ActiveStatusID int  = NULL ,
	@CommercialTrunkID int  = NULL ,
	@DirectionID int  = NULL ,
	@TimeZoneShiftMinutes int  = NULL ,
	@CLLI varchar(30)  = NULL ,
	@OrigPointCode varchar(30)  = NULL ,
	@PointCode varchar(30)  = NULL ,
	@ReportCode varchar(30)  = NULL ,
	@Description varchar(255)  = NULL ,
	@Note varchar(max)  = NULL ,
	@TrunkIPAddress varchar(30)  = NULL ,
	@TransmissionTypeID int  = NULL ,
	@SignalingTypeID int  = NULL ,
	@ProcessCode char(1)  = NULL ,
	@TargetUsage int  = NULL ,
	@UserID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ResultFlag = 0
set @ErrorDescription = NULL

set @Trunk = rtrim(ltrim(@Trunk))

------------------------------------------------------------------------
-- Perform all essential preliminary checks before updating record for
-- the technical trunk
------------------------------------------------------------------------

if (@TrunkID is NULL)
Begin

		set @ErrorDescription = 'ERROR !!! Trunk ID cannot be NULL'
		set @ResultFlag = 1
		return 1 

End

if (@AccountID is NULL)
Begin

		set @ErrorDescription = 'ERROR !!! Account ID cannot be NULL'
		set @ResultFlag = 1
		return 1 

End

if not exists ( select 1 from tb_trunk where trunkID = @TrunkID )
Begin

		set @ErrorDescription = 'ERROR !!! Technical trunk does not exist in the system for the respective ID '
		set @ResultFlag = 1
		return 1 

End

----------------------------------------------------------
-- Check Originating switch should not be NULL for
-- any kind of Technical Trunk
----------------------------------------------------------

if (  @SwitchID is NULL )
Begin

		set @ErrorDescription = 'ERROR !!! Originating switch not provided for Technical Trunk'
		set @ResultFlag = 1
		return 1 

End


Declare @OldCDRMatch varchar(30),
        @OldSwitchID int,
		@OldAccountID int

Select @OldCDRMatch = CDRMatch,
       @OldSwitchID = SwitchID,
	   @OldAccountID = AccountID
from tb_trunk
where TrunkID = @TrunkID

--------------------------------------------------------
-- The old and new switch and account should be same
--------------------------------------------------------

if ( @OldSwitchID <> @SwitchID )
Begin

		set @ErrorDescription = 'ERROR !!! Cannot change the switch for the existing trunk. Create new trunk record if switch is being changed'
		set @ResultFlag = 1
		return 1 

End

if ( @OldAccountID <> @AccountID )
Begin

		set @ErrorDescription = 'ERROR !!! Cannot change the account for existing trunk. Create new trunk record if account is being changed'
		set @ResultFlag = 1
		return 1 

End

------------------------------------------------------------------------------------------------
-- Check if trunk already exists in the system for combination of TRUNK , ACCOUNTID and SWITCHID
------------------------------------------------------------------------------------------------

if exists ( select 1 from tb_trunk where trunk = rtrim(ltrim(@Trunk)) and AccountID = @AccountID and @SwitchID = @SwitchID  and TrunkID <> @TrunkID and flag & 1 <> 1)
Begin

		set @ErrorDescription = 'ERROR !!! There is already physical trunk(s) existing in the system for the combination of TRUNK , ACCOUNT and SWITCH'
		set @ResultFlag = 1
		return 1 

End

----------------------------------------------------------
-- Check that the terminating switch is provided for an
-- IMT trunk. Inacase it is not an IMT trunk, then we
-- do not need the terminating switch
----------------------------------------------------------

if ( ( @TrunkTypeID = 5 ) and ( @TSwitchID is NULL ) )
Begin

		set @ErrorDescription = 'ERROR !!! Terminating switch not provided for Inter Machine Trunk'
		set @ResultFlag = 1
		return 1 

End


----------------------------------------------------------
-- Originating and terminating switches should not be the
-- same
----------------------------------------------------------

if ( (@TSwitchID is not NULL ) and (@SwitchID = @TSwitchID ))

Begin

		set @ErrorDescription = 'ERROR !!! Originating and terminating switches cannot be the same'
		set @ResultFlag = 1
		return 1 

End


----------------------------------------------------------
-- Check CDRMATCH should not be NULL for
-- any kind of Technical Trunk
----------------------------------------------------------

if (  @CDRMatch is NULL )
Begin

		set @ErrorDescription = 'ERROR !!! CDR Match for Technical Trunk is not provided'
		set @ResultFlag = 1
		return 1 

End

set @CDRMatch = rtrim(ltrim(@CDRMatch))

-------------------------------------------------------------
-- The originating switch should be physical switch and not
-- commercial for a technical trunk
-------------------------------------------------------------

if exists ( 
			select 1 from tb_switch tbl1 
			inner join tb_SwitchType tbl2 on tbl1.SwitchTypeID = tbl2.SwitchTypeID
			where tbl1.SwitchID = @SwitchID
			and tbl2.SwitchTypeID = 5
		  )

Begin

		set @ErrorDescription = 'ERROR !!! Canot assign Commercial switch to a Techncical/Physical Trunk'
		set @ResultFlag = 1
		return 1 

End

----------------------------------------------------------------------------------------
-- Before updating trunk record into the  database, check if any overlapping
-- records exist or not
----------------------------------------------------------------------------------------
-- We need to check the same twice. Once for the old CDRMATCH, and the other
-- time for new CDRMATCH.
-- It is possible that the update of CDRMATCH could cause overlapping active
-- records for old and new CDRMATCH 
----------------------------------------------------------------------------------------
 
Declare @ResultFlag2 int = 0

if ( ltrim(rtrim(@CDRMatch)) <>  ltrim(rtrim(@OldCDRMatch)) )
Begin

			------------------------------------------------------------------------------------------
			 -- Check if there is a active record already exising for the the new CDRMatch , Switch 
			------------------------------------------------------------------------------------------

			Exec SP_BSCheckOverlappingActiveTrunksOnUpdate @CDRMatch , @SwitchID , @EffectiveDate , @ActiveStatusID , @TrunkID , 1, @ResultFlag2 output

			if ( @ResultFlag2 = 1 )
			Begin

					set @ErrorDescription = 'ERROR !!! The update causes overlapping records for the new CDRMatch : ' + @CDRMatch + ' in the system'
					set @ResultFlag = 1
					return 1 	

			End

			------------------------------------------------------------------------------------------
			 -- Check if there is a active record already exising for the the old CDRMatch , Switch 
			------------------------------------------------------------------------------------------

			set @ResultFlag2 = 0

			Exec SP_BSCheckOverlappingActiveTrunksOnUpdate @OldCDRMatch , @OldSwitchID , @EffectiveDate , @ActiveStatusID , @TrunkID , 0 , @ResultFlag2 output

			if ( @ResultFlag2 = 1 )
			Begin

					set @ErrorDescription = 'ERROR !!! The update causes overlapping records for the old CDRMatch : ' + @OldCDRMatch + ' in the system'
					set @ResultFlag = 1
					return 1 	

			End

End

--------------------------------
-- Update record in the system
--------------------------------

	Begin Try

			Update tb_trunk set
			Trunk = rtrim(ltrim(@Trunk)),
			CLLI = @CLLI,
			OrigPointCode = @OrigPointCode,
			PointCode = @PointCode,
			ReportCode = @ReportCode,
			[Description] = @Description,
			Note = @Note,
			CDRMatch = rtrim(ltrim(@CDRMatch)),
			TrunkIPAddress = @TrunkIPAddress,
			TimeZoneShiftMinutes = @TimeZoneShiftMinutes,
			TrunkTypeID = @TrunkTypeID,
			SwitchID = @SwitchID,
			TSwitchID = @TSwitchID,
			AccountID = @AccountID,
			TransmissionTypeID = @TransmissionTypeID,
			SignalingTypeID = @SignalingTypeID,
			ModifiedDate = getdate(),
			ModifiedByID = @UserID,
			Flag = 0
			Where trunkID = @TrunkID


	End Try

	Begin Catch

			set @ErrorDescription = 'ERROR!!! Updating record for technical trunk : ' + @Trunk 
			set @ResultFlag = 1
			Return 1

	End Catch

  





GO
