USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICreateNewReference]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_UICreateNewReference] 
(
   @ReferenceNo			varchar(100),
   @AccountID			int,
   @OfferTemplateID		int = NULL,
   @VendorSourceID		int = NULL,
   @VendorValueSourceID		int = NULL, 
   @ParseTemplateName		varchar(200),
   @MultipleSheetsInOffer	int,
   @AutoOfferUploadFlag		int,
   @SkipRateIncreaseFlag	int,
   @EnableEmailCheck		int,
   @RateIncreasePeriod          int,
   @CheckNewDestination         int,
   @UserID			int,
   @ResultFlag			int	Output,
   @ErrorDescription		varchar(2000) Output
)
--With Encryption 
As

Declare @ErrorMsgStr varchar(2000)


set @ResultFlag = 0
set @ErrorDescription = NULL

------------------------------------------------------------
-- VALIDATION 1: Check if the session user has the essential
-- privilege to create new reference
------------------------------------------------------------

Declare @ReturnFlag int

Exec SP_UICheckUserPrivilegeRole @UserID , 'Create New Reference' , @ReturnFlag output

if (@ReturnFlag = 0)
Begin

	set @ErrorDescription = 'Logged User does not have privilege to create new reference'
	set @ResultFlag = 1
	return

End

-----------------------------------------------------------
-- Perform essential validation on the input parameters
-----------------------------------------------------------

-----------------
-- REFERENCE NO
-----------------

if ( @ReferenceNo is null )
Begin

	set @ErrorDescription = 'Reference No passed to create new reference API is NULL'
	set @ResultFlag = 1
	return

End

----------------------------------------------------
-- Check the format of Reference No field
----------------------------------------------------

Declare @TempReferenceNo varchar(100)

set @TempReferenceNo = replace(@ReferenceNo , '/' , '')

if (( len(@ReferenceNo) - len(@TempReferenceNo)) <> 4) 
Begin

	set @ErrorDescription = 'Format of the ReferenceNo value is not correct. Allowed format is <Tag/Currency/Service/Traffic Type/Direction>'
	set @ResultFlag = 1
	return

End

-----------------
-- ACCOUNT ID
----------------

Declare @Account varchar(100)

if ( @AccountID is null )
Begin

	set @ErrorDescription = 'Account ID passed to API for creating new reference is NULL'
	set @ResultFlag = 1
	return 1
End

if not exists (  select 1 from vw_Accounts where accountid = @AccountID )
Begin

	set @ErrorDescription = 'No Account exists in the system by the for ID : ' + convert(varchar(10) , @AccountID)
	set @ResultFlag = 1
	return 1 
End


select @Account = account from vw_Accounts where accountid = @AccountID

---------------------
-- VENDOR SOURCE ID
---------------------

if (@VendorSourceID is null )
Begin

	set @ErrorDescription = 'Vendor Source ID passed to API for creating new reference is NULL'
	set @ResultFlag = 1
	return 1

End


if (  ( @VendorSourceID is not null ) and  not exists (  select 1 from vw_VendorSource where sourceid = @VendorSourceID ) )
Begin

	set @ErrorDescription = 'No vendor exists in the system by the for ID : ' + convert(varchar(10) , @VendorSourceID)
	set @ResultFlag = 1
	return 1
End

--------------------------------------------------------------------------
-- Check to ensure that the AccountId of the Vendor Source is same
-- as the AccountID of the reference being created in the system
--------------------------------------------------------------------------

Declare @VendorAccountID int

select @VendorAccountID = AccountID
from vw_VendorSource
where SourceID = @VendorSourceID

if ( @VendorAccountID <> @AccountID)
Begin

	set @ErrorDescription = 'Account of the Vendor Source and the Reference No being created are not the same'
	set @ResultFlag = 1
	return 1
End


---------------------
-- OFFER TEMPLATE ID
---------------------


if (  ( @OfferTemplateID is not null ) and  not exists (  select 1 from vw_OfferTemplate where OfferTemplateID = @OfferTemplateID ) )
Begin

	set @ErrorDescription = 'No offer template exists in the system by the for ID : ' + convert(varchar(10) , @OfferTemplateID)
	set @ResultFlag = 1
	return 1
End


-------------------------------------------------------------
-- Check the config paramater for Vendor Extended Source
-------------------------------------------------------------

Declare @AllowExtendedVendorSources int

Select @AllowExtendedVendorSources = convert(int ,ConfigValue)
from tb_Config
where Configname = 'AllowExtendedVendorSources'

if @AllowExtendedVendorSources is NULL
	set @AllowExtendedVendorSources = 0


if ( @AllowExtendedVendorSources <> 0 ) -- Allow Extended Vendor Sources
Begin

		--------------------------
		-- VENDOR VALUE SOURCE ID
		--------------------------


		if (  ( @VendorValueSourceID is not null ) and  not exists (  select 1 from vw_VendorSource where sourceid = @VendorValueSourceID ) )
		Begin

			set @ErrorDescription = 'No extended vendor exists in the system the for ID : ' + convert(varchar(10) , @VendorValueSourceID)
			set @ResultFlag = 1
			return 1
		End

		if (  @VendorValueSourceID is not null )
		Begin
		
				Declare @ExtendedVendorAccountID int

				select @ExtendedVendorAccountID = AccountID
				from vw_VendorSource
				where SourceID = @VendorValueSourceID

				if ( @ExtendedVendorAccountID <> @AccountID)
				Begin

					set @ErrorDescription = 'Account of the Extended Vendor Source and the Reference No being created are not the same'
					set @ResultFlag = 1
					return 1
				End

				if ( @VendorValueSourceID = @VendorSourceID )
				Begin
				
					set @ErrorDescription = 'The Vendor Source and Extended Vendor Source cannot be the same'
					set @ResultFlag = 1
					return 1

				End

		End

End
Else
Begin

	set @VendorValueSourceID = NULL


End



-----------------------------
-- MULTIPLE SHEETS IN OFFER
-----------------------------

if ( @MultipleSheetsInOffer is null )
Begin

	set @ErrorDescription = 'MultipleSheetsInOffer parameter is NULL. Valid values are 1 or 0'
	set @ResultFlag = 1
	return 1
End

if ( @MultipleSheetsInOffer not in (0,1) )
Begin

	set @ErrorDescription = 'Value for MultipleSheetsInOffer parameter is not valid . Allowed values are 1 or 0'
	set @ResultFlag = 1
	return 1
End

-----------------------------
-- AUTO OFFER UPLOAD FLAG
-----------------------------

if ( @AutoOfferUploadFlag is null )
Begin

	set @ErrorDescription = 'AutoOfferUploadFlag parameter is NULL. Valid values are 1 or 0'
	set @ResultFlag = 1
	return 1
End

if ( @AutoOfferUploadFlag not in (0,1) )
Begin

	set @ErrorDescription = 'Value for AutoOfferUploadFlag parameter is not valid . Allowed values are 1 or 0'
	set @ResultFlag = 1
	return 1
End


-----------------------------
-- SKIP RATE INCREASE FLAG
-----------------------------

if ( @SkipRateIncreaseFlag is null )
Begin

	set @ErrorDescription = 'SkipRateIncreaseFlag parameter is NULL. Valid values are 1 (Yes) or 0 (No)'
	set @ResultFlag = 1
	return 1
End

if ( @SkipRateIncreaseFlag not in (0,1) )
Begin

	set @ErrorDescription = 'Value for SkipRateIncreaseFlag parameter is not valid . Allowed values are 1 (Yes) or 0 (No)'
	set @ResultFlag = 1
	return 1
End


-----------------------------
-- CHECK NEW DESTINATION FLAG
-----------------------------

if ( @CheckNewDestination is null )
Begin

	set @ErrorDescription = 'CheckNewDestination parameter is NULL. Valid values are 1 (Yes) or 0 (No)'
	set @ResultFlag = 1
	return 1
End

if ( @CheckNewDestination not in (0,1) )
Begin

	set @ErrorDescription = 'Value for CheckNewDestination parameter is not valid . Allowed values are 1 (Yes) or 0 (No)'
	set @ResultFlag = 1
	return 1
End

-----------------------------
-- ENABLE EMAIL CHECK FLAG
-----------------------------

if ( @EnableEmailCheck is null )
Begin

	set @ErrorDescription = 'EnableEmailCheck parameter is NULL. Valid values are 1 (Yes) or 0 (No)'
	set @ResultFlag = 1
	return 1
End


---------------------------------------------------------------------------------
-- Added Change 28th Jan 2012
-- When creating a new reference, the default value for "EnableEmailCheck" flag
-- has to be 0, becuase at this point of time there are no authorized email ids
-- configured for the reference.
---------------------------------------------------------------------------------

if ( @EnableEmailCheck <> 0 )
Begin

	set @ErrorDescription = 'Value for EnableEmailCheck parameter during reference creation should be set to "NO". Post reference creation authorized senders can be configured and check can be enable.'
	set @ResultFlag = 1
	return 1
End

-----------------------------
-- RATE INCREASE PERIOD
-----------------------------

if ( isnumeric(@RateIncreasePeriod) <> 1 )
Begin

	set @ErrorDescription = 'Value for RateIncreasePeriod parameter is not numeric . Value should be greater than equal to 0'
	set @ResultFlag = 1
	return 1
End

if ( @RateIncreasePeriod < 0 )
Begin
 
	set @ErrorDescription = 'Value for RateIncreasePeriod parameter is not valid . Value should be greater than equal to 0'
	set @ResultFlag = 1
	return 1
End


if (( @ParseTemplateName  is not null ) and (len(@ParseTemplateName ) = 0) )
Begin

	set @ParseTemplateName  = NULL

End

if ( @ParseTemplateName is null )
Begin

	set @ErrorDescription = 'Name passed for parsing format file to create new reference is NULL'
	set @ResultFlag = 1
	return 1
End



------------------------------------------------------
-- Insert data into the table for the new reference
------------------------------------------------------

Begin Try

	insert into tb_vendorreferencedetails
	(
		Account,
		ReferenceNo,
		Accountid,
		VendorSourceid,
		OfferTemplateID,
		VendorValueSourceid,
		MultipleSheetsInOffer,
		ParseTemplateName,
		AutoOfferUploadFlag,
		SkipRateIncreaseCheck,
		EnableEmailCheck,
		RateIncreasePeriod,
		CheckNewDestination,
		ModifiedDate,
		ModifiedByID
	)
	values
	(
		@Account,
		@ReferenceNo,
		@AccountID,
		@VendorSourceID,
		@OfferTemplateID,
		@VendorValueSourceID,
		@MultipleSheetsInOffer,
		@ParseTemplateName,
		@AutoOfferUploadFlag,
		@SkipRateIncreaseFlag,
		@EnableEmailCheck,
		@RateIncreasePeriod,
		@CheckNewDestination,
		getdate(),
		@UserID

	)

End Try

Begin Catch

	set @ErrorDescription = ERROR_MESSAGE()
	set @ResultFlag = 1
	return 1

End Catch
GO
