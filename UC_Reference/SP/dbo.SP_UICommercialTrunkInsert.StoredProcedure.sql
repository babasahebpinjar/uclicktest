USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICommercialTrunkInsert]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  StoredProcedure [dbo].[SP_UITechnicalTrunkInsert]    Script Date: 24-02-2014 15:58:04 ******/
CREATE procedure [dbo].[SP_UICommercialTrunkInsert]
(
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

if exists ( select 1 from tb_trunk where trunk = rtrim(ltrim(@Trunk)) and AccountID = @AccountID and @SwitchID = @SwitchID  and flag & 1 <> 1)
Begin

		set @ErrorDescription = 'ERROR !!! There is already Commercial trunk(s) existing in the system for the combination of TRUNK , ACCOUNT and SWITCH'
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


---------------------------------------------------------------
-- Open Transaction block to insert record in the system
---------------------------------------------------------------

Begin Transaction InsertRecCT

    ---------------------
	-- TB_TRUNK Record
	---------------------

	Begin Try

			Insert into tb_trunk
			(
				Trunk,
				CDRMatch,
				[Description],
				Note,
				TrunkTypeID,
				SwitchID,
				AccountID,
				ModifiedDate,
				ModifiedByID,
				Flag
			)
			Values
			(
				rtrim(ltrim(@Trunk)),
				rtrim(ltrim(@Trunk)), -- Update the CDR match as the name of the trunk
				@Description,
				@Note,
				@TrunkTypeID, -- Default for Commercial Trunk Type
				@SwitchID,
				@AccountID,
				getdate(),
				@UserID,
				0
			)

	End Try

	Begin Catch

			set @ErrorDescription = 'ERROR!!! Inserting new record for Commercial trunk : ' + @Trunk 
			set @ResultFlag = 1
			Rollback Transaction InsertRecCT
			Return 1

	End Catch

    -------------------------
	-- TB_TRUNKDETAIL Record
	------------------------

	Begin Try

			Select @TrunkID = trunkID
			from tb_trunk
			where accountID = @AccountID
			and trunk = @Trunk
			and SwitchID = @SwitchID
			and @TrunkTypeID = 9
			
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

	End Try

	Begin Catch

			set @ErrorDescription = 'ERROR!!! Inserting attribute details for technical trunk : ' + @Trunk 
			set @ResultFlag = 1
			Rollback Transaction InsertRecCT
			Return 1

	End Catch

Commit Transaction InsertRecCT





GO
