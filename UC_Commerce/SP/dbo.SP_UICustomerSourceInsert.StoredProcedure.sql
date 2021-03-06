USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICustomerSourceInsert]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UICustomerSourceInsert]
(
	@Source varchar(60),
	@SourceAbbrv varchar(30),
	@StatusID int,
	@AccountID int,
	@RatePlanID int,
	@CallTypeID int,
	@ReferencePriceListID int = NULL,
	@Note varchar(8000) = NULL,
	@UserID int,
	@ErrorDescription varchar(2000) output,
	@ResultFlag int output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

----------------------------------------------
-- Set the Source Type to -3 (Customer Source)
----------------------------------------------

Declare @SourceTypeID int = -3 -- Hard coded to -3  which is source id for Customer Source

-------------------------------------------------------
-- Check to ensure that Source and Abbrv are not NULL
-------------------------------------------------------

set @Source = ltrim(rtrim(@Source))
set @SourceAbbrv = ltrim(rtrim(@SourceAbbrv))

if ( (@Source is NULL) or (len(@Source) = 0) )
Begin

	set @ErrorDescription = 'ERROR !!!! Customer Source Name cannot be NULL or blank'
	set @ResultFlag = 1
	return 1

End

if ( (@SourceAbbrv is NULL) or (len(@SourceAbbrv) = 0) )
Begin

	set @ErrorDescription = 'ERROR !!!! Customer Source Abbreviation cannot be NULL or blank'
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

	set @ErrorDescription = 'ERROR !!!! Customer Status ID cannot be NULL or an invalid value'
	set @ResultFlag = 1
	return 1

End

--------------------------------------------------------------
-- Check to ensure that Source and Source Type are unique
--------------------------------------------------------------

if exists ( select 1 from tb_Source where ltrim(rtrim([source])) = @Source and SourceTypeID = @SourceTypeID )
Begin

	set @ErrorDescription = 'ERROR !!!! Customer Source Name and Source Type combination already exists'
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

	set @ErrorDescription = 'ERROR !!!! Rate Plan Account does not match the selected Account for Customer Source creation'
	set @ResultFlag = 1
	return 1

End


-------------------------------------------------------------------
-- Check to ensure that no other vendor source exists in the 
-- system for the combination of Rate Plan and Call Type
-------------------------------------------------------------------

if exists ( select 1 from tb_Source where RatePlanID = @RatePlanID and CallTypeID = @CallTypeID and SourceTypeID =  @SourceTypeID )
Begin

	set @ErrorDescription = 'ERROR !!!! Customer Source already exists in the system for the rateplan and calltype'
	set @ResultFlag = 1
	return 1
	
End


---------------------------------------------------------------
-- Insert Record into the database for the new Customer Source
---------------------------------------------------------------
Declare @NoteID int

Begin Transaction CSR

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
			ReferencePriceListID,
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
			@ReferencePriceListID,
			GetDate(),
			@UserID,
			0
			
	   )

End Try


Begin Catch


	set @ErrorDescription = 'ERROR !!!! During Customer Source creation. ' + ERROR_MESSAGE()
	Rollback Transaction CSR
	set @ResultFlag = 1
	return 1

End Catch

Commit Transaction CSR

Return 0



GO
