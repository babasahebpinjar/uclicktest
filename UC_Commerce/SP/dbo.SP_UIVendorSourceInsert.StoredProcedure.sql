USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIVendorSourceInsert]    Script Date: 5/2/2020 6:18:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIVendorSourceInsert]
(
	@Source varchar(60),
	@SourceAbbrv varchar(30),
	@StatusID int,
	@AccountID int,
	@RatePlanID int,
	@CallTypeID int,
	@Note varchar(8000) = NULL,
	@UserID int,
	@ErrorDescription varchar(2000) output,
	@ResultFlag int output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

----------------------------------------------
-- Set the Source Type to -1 (Vendor Source)
----------------------------------------------

Declare @SourceTypeID int = -1 -- Hard coded to -1  which is source id for Vendor Source

-------------------------------------------------------
-- Check to ensure that Source and Abbrv are not NULL
-------------------------------------------------------

set @Source = ltrim(rtrim(@Source))
set @SourceAbbrv = ltrim(rtrim(@SourceAbbrv))

if ( (@Source is NULL) or (len(@Source) = 0) )
Begin

	set @ErrorDescription = 'ERROR !!!! Vendor Source Name cannot be NULL or blank'
	set @ResultFlag = 1
	return 1

End

if ( (@SourceAbbrv is NULL) or (len(@SourceAbbrv) = 0) )
Begin

	set @ErrorDescription = 'ERROR !!!! Vendor Source Abbreviation cannot be NULL or blank'
	set @ResultFlag = 1
	return 1

End

-------------------------------------------------------------------
-- Check to ensure that AcccountID , Call TypeID and RatePlanID
-- passed to the API are valid and exist
-------------------------------------------------------------------

if ( ( @AccountID is Null) or not exists (select 1 from UC_Reference.dbo.Tb_Account where accountID = @AccountID) )
Begin

	set @ErrorDescription = 'ERROR !!!! Account ID cannot be NULL or an invalid value'
	set @ResultFlag = 1
	return 1

End

if ( ( @CallTypeID is Null) or not exists (select 1 from UC_Reference.dbo.tb_CallType where CallTypeID = @CallTypeID) )
Begin

	set @ErrorDescription = 'ERROR !!!! CallType ID cannot be NULL or an invalid value'
	set @ResultFlag = 1
	return 1

End

if ( ( @RatePlanID is Null) or not exists (select 1 from UC_Reference.dbo.tb_RatePlan where RatePlanID = @RatePlanID) )
Begin

	set @ErrorDescription = 'ERROR !!!! RatePlan ID cannot be NULL or an invalid value'
	set @ResultFlag = 1
	return 1

End

if ( ( @StatusID is Null) or not exists (select 1 from UC_Reference.dbo.tb_ActiveStatus where ActiveStatusID = @StatusID) )
Begin

	set @ErrorDescription = 'ERROR !!!! Vendor Status ID cannot be NULL or an invalid value'
	set @ResultFlag = 1
	return 1

End

--------------------------------------------------------------
-- Check to ensure that Source and Source Type are unique
--------------------------------------------------------------

if exists ( select 1 from tb_Source where ltrim(rtrim([source])) = @Source and SourceTypeID = @SourceTypeID )
Begin

	set @ErrorDescription = 'ERROR !!!! Vendor Source Name and Source Type combination already exists'
	set @ResultFlag = 1
	return 1

End

-----------------------------------------------------------------------
-- Check to ensure that the AccountID and Raterplan's accountID match
-----------------------------------------------------------------------

Declare @RPAccountID int,
        @CurrencyID int

Select @RPAccountID = Acc.AccountID,
       @CurrencyID = Rp.CurrencyID
from UC_Reference.dbo.tb_RatePlan Rp
inner join UC_Reference.dbo.tb_Agreement Agr on Rp.AgreementID = Agr.AgreementID
inner join UC_Reference.dbo.tb_Account Acc on Agr.AccountID = Acc.AccountID
where Rp.RatePlanID = @RatePlanID

if ( @AccountID <> @RPAccountID )
Begin

	set @ErrorDescription = 'ERROR !!!! Rate Plan Account does not match the selected Account for Vendor Source creation'
	set @ResultFlag = 1
	return 1

End


-------------------------------------------------------------------
-- Check to ensure that no other vendor source exists in the 
-- system for the combination of Rate Plan and Call Type
-------------------------------------------------------------------

if exists ( select 1 from tb_Source where RatePlanID = @RatePlanID and CallTypeID = @CallTypeID and SourceTypeID =  @SourceTypeID )
Begin

	set @ErrorDescription = 'ERROR !!!! Vendor Source already exists in the system for the rateplan and calltype'
	set @ResultFlag = 1
	return 1
	
End


---------------------------------------------------------------
-- Insert Record into the database for the new Vendor Source
---------------------------------------------------------------
Declare @NoteID int,
        @VendorSourceID int,
		@NumberPlan varchar(100),
		@NumberPlanAbbrv varchar(60)

select @NumberPlan = @Source + ' ' + CallType,
       @NumberPlanAbbrv = @SourceAbbrv + ' ' + CallTypeAbbrv
from UC_Reference.dbo.tb_CallType CT
where calltypeID = @CallTypeID

Begin Transaction VSR

Begin Try

        ------------------------------
		-- Record in TB_NOTE table
		------------------------------
		Insert into tb_Note 
		(
			Content,
			ModifiedDate,
			ModifiedByID,
			Flag
		)
		Values
		(
			@Note,
			GetDate(),
			@UserID,
			0
		)

       set @NoteID = @@IDENTITY

        ------------------------------
		-- Record in TB_SOURCE table
		------------------------------

	   Insert into tb_Source
	   (
			ActiveStatusID,
			[Source],
			SourceAbbrv,
			SourceTypeID,
			NoteID,
			ExternalCode,
			RatePlanID,
			CurrencyID,
			CallTypeID,
			ModifiedDate,
			ModifiedByID,
			Flag
	   )
	   Values
	   (
			@StatusID,
			@Source,
			@SourceAbbrv,
			@SourceTypeID,
			@NoteID,
			@AccountID,
			@RatePlanID,
			@CurrencyID,
			@CallTypeID,
			GetDate(),
			@UserID,
			0
			
	   )

	   -------------------------------------------------------
	   -- Create an entry in the numberplan table, associated
	   -- with the new vendor source
	   -------------------------------------------------------

	   select @VendorSourceID = SourceID
	   from tb_Source
	   where SourceTypeID = @SourceTypeID
	   and RatePlanID = @RatePlanID
	   and CallTypeID = @CallTypeID 

	   if not exists ( select 1 from UC_Reference.dbo.tb_numberplan where ExternalCode = @VendorSourceID )
	   Begin

			   -------------------------------------
			   -- Record TB_NUMBERPLAN table
			   -------------------------------------

			   Insert into UC_Reference.dbo.tb_NumberPlan
			   (
					NumberPlan,
					NumberPlanAbbrv,
					ExternalCode,
					NumberPlanTypeID,
					ModifiedDate,
					ModifiedByID,
					Flag
			   )
			   Values
			   (
					@NumberPlan,
					@NumberPlanAbbrv,
					@VendorSourceID,
					2, -- Vendor Number Plan 
					GetDate(),
					@UserID,
					0
			   ) 

	   End
	   
End Try


Begin Catch


	set @ErrorDescription = 'ERROR !!!! During Vendor Source creation. ' + ERROR_MESSAGE()
	Rollback Transaction VSR
	set @ResultFlag = 1
	return 1

End Catch

Commit Transaction VSR

Return 0



GO
