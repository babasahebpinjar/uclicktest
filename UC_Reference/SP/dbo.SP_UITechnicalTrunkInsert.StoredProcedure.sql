USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UITechnicalTrunkInsert]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_UITechnicalTrunkInsert]
(
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


Declare @TrunkID int 

set @ResultFlag = 0
set @ErrorDescription = NULL

set @Trunk = rtrim(ltrim(@Trunk))

------------------------------------------------------------------------
-- Perform all essential preliminary checks before inserting a record
-- for a new Technical Trunk in the system
------------------------------------------------------------------------

------------------------------------------------------------------------------------------------
-- Check if trunk already exists in the system for combination of TRUNK , ACCOUNTID and SWITCHID
------------------------------------------------------------------------------------------------

if exists ( select 1 from tb_trunk where trunk = rtrim(ltrim(@Trunk)) and AccountID = @AccountID and SwitchID = @SwitchID  and flag & 1 <> 1)
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
-- Check Originating switch should not be NULL for
-- any kind of Technical Trunk
----------------------------------------------------------

if (  @SwitchID is NULL )
Begin

		set @ErrorDescription = 'ERROR !!! Originating switch not provided for Technical Trunk'
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


----------------------------------------------------------------------
-- Technical trunk should have a valid Commercial trunk assigned to it
----------------------------------------------------------------------

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

----------------------------------------------------------------------------------------
-- Before inserting the new trunk record into the  database, check if any overlapping
-- records exist or not
----------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------
 -- Check if there is a active record already exising for the the same effective date,
 -- CDRMatch , Switch
 -------------------------------------------------------------------------------------
 
	Declare @ResultFlag2 int = 0

	Exec SP_BSCheckOverlappingActiveTrunksOnInsert @CDRMatch , @SwitchID , @EffectiveDate , @ActiveStatusID ,  @ResultFlag2 output

	if ( @ResultFlag2 = 1 )
	Begin

			set @ErrorDescription = 'ERROR !!! There are overlapping records for the CDRMatch : ' + @CDRMatch + ' in the system'
			set @ResultFlag = 1
			return 1 	

	End



---------------------------------------------------------------
-- Open Transaction block to insert record in the system
---------------------------------------------------------------

Begin Transaction InsertRecTT

    ---------------------
	-- TB_TRUNK Record
	---------------------

	Begin Try

			Insert into tb_trunk
			(
				Trunk,
				CLLI,
				OrigPointCode,
				PointCode,
				ReportCode,
				[Description],
				Note,
				CDRMatch,
				TrunkIPAddress,
				TimeZoneShiftMinutes,
				TrunkTypeID,
				SwitchID,
				TSwitchID,
				AccountID,
				TransmissionTypeID,
				SignalingTypeID,
				ModifiedDate,
				ModifiedByID,
				Flag
			)
			Values
			(
				rtrim(ltrim(@Trunk)),
				@CLLI,
				@OrigPointCode,
				@PointCode,
				@ReportCode,
				@Description,
				@Note,
				rtrim(ltrim(@CDRMatch)),
				@TrunkIPAddress,
				@TimeZoneShiftMinutes,
				@TrunkTypeID,
				@SwitchID,
				@TSwitchID,
				@AccountID,
				@TransmissionTypeID,
				@SignalingTypeID,
				getdate(),
				@UserID,
				0
			)

	End Try

	Begin Catch

			set @ErrorDescription = 'ERROR!!! Inserting new record for technical trunk : ' + @Trunk 
			set @ResultFlag = 1
			Rollback Transaction InsertRecTT
			Return 1

	End Catch

    -------------------------
	-- TB_TRUNKDETAIL Record
	------------------------

	Begin Try

			Select @TrunkID = trunkID
			from tb_trunk
			where accountID = @AccountID
			and CDRMatch = @CDRMatch
			and trunk = @Trunk
			and SwitchID = @SwitchID
			
			insert into tb_TrunkDetail
			(
				EffectiveDate,
				ActivatedPorts,
				AvailablePorts,
				ProcessCode,
				TargetUsage,
				TrunkID,
				ActiveStatusID,
				CommercialTrunkID,
				DirectionID,
				ModifiedDate,
				ModifiedByID,
				Flag
			)
			values
			(
				@EffectiveDate,
				@ActivatedPorts,
				@AvailablePorts,
				@ProcessCode,
				@TargetUsage,
				@TrunkID,
				@ActiveStatusID,
				@CommercialTrunkID,
				@DirectionID,
				getdate(),
				@UserID,
				0
			)

	End Try

	Begin Catch

			set @ErrorDescription = 'ERROR!!! Inserting attribute details for technical trunk : ' + @Trunk 
			set @ResultFlag = 1
			Rollback Transaction InsertRecTT
			Return 1

	End Catch

Commit Transaction InsertRecTT





GO
