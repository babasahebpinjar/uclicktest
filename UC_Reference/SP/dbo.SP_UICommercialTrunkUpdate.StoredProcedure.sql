USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICommercialTrunkUpdate]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_UICommercialTrunkUpdate]
(
    @TrunkID int,
	@Trunk varchar(60)  ,
	@TrunktypeID int,
	@SwitchID int  ,
	@AccountID int  ,
	@EffectiveDate datetime  ,
	@ActiveStatusID int  = NULL ,
	@DirectionID int  = NULL ,
	@Description varchar(255)  = NULL ,
	@Note varchar(max)  = NULL ,
	@UserID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As


set @ResultFlag = 0
set @ErrorDescription = NULL

set @Note = isnull(@Note ,'')
set @Description = isnull(@Description , '')

set @Trunk = rtrim(ltrim(@Trunk))

------------------------------------------------------------------------
-- Perform all essential preliminary checks before updating record for
-- the Commercial trunk
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

		set @ErrorDescription = 'ERROR !!! Commercial trunk does not exist in the system for the respective ID '
		set @ResultFlag = 1
		return 1 

End

----------------------------------------------------------
-- Check Originating switch should not be NULL for
-- any kind of Commercial Trunk
----------------------------------------------------------

if (  @SwitchID is NULL )
Begin

		set @ErrorDescription = 'ERROR !!! Originating switch not provided for Commercial Trunk'
		set @ResultFlag = 1
		return 1 

End

----------------------------------------------------------
-- Originating switch should be of the type Commercial
----------------------------------------------------------

if not exists ( select 1 from tb_Switch where switchid = @SwitchID and SwitchTypeID = 5)

Begin

		set @ErrorDescription = 'ERROR !!! Commercial trunk should always default to switch of the type COMMERCIAL'
		set @ResultFlag = 1
		return 1 

End


Declare @OldSwitchID int,
		@OldAccountID int,
		@OldTrunk varchar(60),
		@OldDescription varchar(255),
		@OldNote varchar(2000)

Select @OldSwitchID = SwitchID,
	   @OldAccountID = AccountID,
	   @OldTrunk = Trunk,
	   @OldDescription = isnull(Description, ''),
	   @OldNote = isnull(Note, '')
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

------------------------------------------------------------------------
-- Perform all essential preliminary checks before inserting a record
-- for a new Technical Trunk in the system
------------------------------------------------------------------------

------------------------------------------------------------------------------------------------
-- Check if trunk already exists in the system for combination of TRUNK , ACCOUNTID and SWITCHID
------------------------------------------------------------------------------------------------

if exists ( select 1 from tb_trunk where trunk = rtrim(ltrim(@Trunk)) and AccountID = @AccountID and @SwitchID = @SwitchID  and flag & 1 <> 1 and TrunkId <> @TrunkID)
Begin

		set @ErrorDescription = 'ERROR !!! There is already Commercial trunk(s) existing in the system for the combination of TRUNK , ACCOUNT and SWITCH'
		set @ResultFlag = 1
		return 1 

End


----------------------------------------------------------
-- Check Direction should not be NULL for
-- any kind of Commercial Trunk
----------------------------------------------------------

if ( @DirectionID is NULL )
Begin

		set @ErrorDescription = 'ERROR !!! Commercial Trunk direction cannot be NULL. It should be either Inbound , Outbound or Bidirectional'
		set @ResultFlag = 1
		return 1 

End

------------------------------------------
-- Trunk Type should be Commercial only
------------------------------------------

if ( @TrunkTypeID <> 9 )
Begin

		set @ErrorDescription = 'ERROR !!! Trunk Type of the Commercial Trunk is not correct'
		set @ResultFlag = 1
		return 1 

End

----------------------------------------------------------------
-- Check if there already exists a trunk detail record in the
-- system for the provided attributes
----------------------------------------------------------------

if exists ( 
			select 1 
			from tb_trunkdetail tbl1
			inner join tb_trunk tbl2 on tbl1.TrunkID = tbl2.TrunkID
			where tbl1.TrunkID = @TrunkID
			and tbl2.trunk = @Trunk
			and DirectionID = @DirectionID
			and ActiveStatusID = @ActiveStatusID
			and EffectiveDate = @EffectiveDate
		   )
Begin

        -------------------------------------------------------
		-- Check if a new NOTE or Description has been added
		-------------------------------------------------------

		if ( (rtrim(ltrim(@Description)) <> ltrim(rtrim(@OldDescription)) ) or (ltrim(rtrim(@Note)) <> ltrim(rtrim(@OldNote))) )
		Begin

				Update tb_trunk
				set Note = @Note,
				    Description = @Description,
				    ModifiedDate = GetDate(),
					ModifiedByID = @UserID
				where TrunkID = @TrunkID

				return 0

		End

		Else
		Begin

				set @ErrorDescription = 'INFO !!! No change in commercial trunk attributes. Update not required'
				set @ResultFlag = 1
				return 1 

		End

End


-------------------------------------------------------------------
-- Check if the same attributes exist for the effective date record
-- lesser to the effective date of new trunk detail
-------------------------------------------------------------------

if exists ( 
			select 1 from tb_trunkdetail tbl1
			inner join tb_trunk tbl2 on tbl1.trunkID = tbl2.TrunkID
			where tbl1.TrunkID = @TrunkID
			and tbl2.Trunk = @Trunk
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

		set @ErrorDescription = 'INFO !!! Immediate historical trunk detail record already exists for the new attributes. Update not required'
		set @ResultFlag = 1
		return 1 

End


---------------------------------------------------------------
-- Open Transaction block to insert record in the system
---------------------------------------------------------------

Begin Transaction UpdateRecCT

    ---------------------
	-- TB_TRUNK Record
	---------------------

	Begin Try

	        if ( ltrim(rtrim(@Trunk)) <> ltrim(rtrim(@OldTrunk)))
			Begin

					Update Tb_Trunk
					set trunk = rtrim(ltrim(@Trunk)),
						CDRMatch = rtrim(ltrim(@Trunk)),
						Note = @Note,
						[Description] = @Description,
					    ModifiedDate = GetDate(),
						ModifiedByID = @UserID
					where TrunkID = @TrunkID

			End

	End Try

	Begin Catch

			set @ErrorDescription = 'ERROR!!! Updating record for Commercial trunk ' 
			set @ResultFlag = 1
			Rollback Transaction UpdateRecCT
			Return 1

	End Catch

    -------------------------
	-- TB_TRUNKDETAIL Record
	------------------------

	Begin Try

	        ---------------------------------------------------------
			-- Update incase a trunk detail record exists for the 
			-- effective date
			---------------------------------------------------------

            if exists ( select 1 from tb_trunkdetail where trunkID = @TrunkID and EffectiveDate = @EffectiveDate )
			Begin

				   Declare @OldActiveStatusID int,
				           @OldDirectionID int


					select @OldActiveStatusID = ActiveStatusID,
					       @OldDirectionID = DirectionID
					from tb_trunkDetail
					where TrunkID = @TrunkID
					and EffectiveDate = @EffectiveDate

			       --------------------------------------------------------------------
				   -- Ony update if there seems to be any change in the trunk attributes
				   --------------------------------------------------------------------

				   if ((@OldActiveStatusID <> @ActiveStatusID) or  (@OldDirectionID <> @DirectionID))
				   Begin

							update tb_TrunkDetail
							set ActiveStatusID = @ActiveStatusID,
								DirectionID = @DirectionID,
								ModifiedDate = GetDate(),
								ModifiedByID = @UserID
							where TrunkID = @TrunkID
							and EffectiveDate = @EffectiveDate

					End


			End

			-----------------------------------------------------------
			-- New trunk detail record to insert due to change in
			-- effective date
			-----------------------------------------------------------

			Else
			Begin

			       ---------------------------------------------------------------------
				   -- There could be a record existing for the attributes on an immediate
				   -- previous date. In this case update is not needed and we dont need
				   -- to insert a new trunk detail record
				   ---------------------------------------------------------------------

					if exists ( 
								select 1 from tb_trunkdetail 
								where TrunkID = @TrunkID
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

							GOTO PROCESSEND

					End

			       ---------------------------------------------------------------------
				   -- There could be a record existing for the attributes on an immediate
				   -- future date. In this we update the effective date of the future 
				   -- record to the passed EFFECTIVE DATE, as the user wants to make
				   -- the future changes effective from this date
				   ---------------------------------------------------------------------

					if exists ( 
								select 1 from tb_trunkdetail 
								where TrunkID = @TrunkID
								and DirectionID = @DirectionID
								and ActiveStatusID = @ActiveStatusID
								and EffectiveDate = 
									  (
										  select Min(EffectiveDate)
										  from tb_trunkdetail
										  where trunkID = @TrunkID
										  and EffectiveDate > @EffectiveDate
									  )
							   )
					Begin

							Update Tb_TrunkDetail
							set Effectivedate = @EffectiveDate,
								ModifiedDate = GetDate(),
								ModifiedByID = @UserID
							where TrunkID = @TrunkID
							and DirectionID = @DirectionID
							and ActiveStatusID = @ActiveStatusID
							and EffectiveDate = 
									  (
										  select Min(EffectiveDate)
										  from tb_trunkdetail
										  where trunkID = @TrunkID
										  and EffectiveDate > @EffectiveDate
									  )

							GOTO PROCESSEND

					End
			
					insert into tb_TrunkDetail
					(
						EffectiveDate,
						TrunkID,
						ActiveStatusID,
						DirectionID,
						ModifiedDate,
						ModifiedByID,
						Flag
					)
					values
					(
						@EffectiveDate,
						@TrunkID,
						@ActiveStatusID,
						@DirectionID,
						getdate(),
						@UserID,
						0
					)
					
			End

	End Try

	Begin Catch

			set @ErrorDescription = 'ERROR!!! Inserting/Updating attribute details for Commercial trunk '
			set @ResultFlag = 1
			Rollback Transaction UpdateRecCT
			Return 1

	End Catch

PROCESSEND:

Commit Transaction UpdateRecCT

Return 0





GO
