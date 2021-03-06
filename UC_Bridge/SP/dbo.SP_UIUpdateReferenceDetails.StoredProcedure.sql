USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIUpdateReferenceDetails]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIUpdateReferenceDetails] 
(
   @ReferenceID int,
   @ReferenceNo varchar(100),
   @MultipleSheetsInOffer int,
   @ParseTemplateName varchar(200),
   @AutoOfferUploadFlag int,
   @SkipRateIncreaseCheck int,
   @EnableEmailCheck int,
   @RateIncreasePeriod int,
   @CheckNewDestination int,
   @UserID int,
   @ResultFlag int Output,
   @ErrorDescription varchar(1000) Output
)
--With Encryption

As

set @ResultFlag = 0
set @ErrorDescription = NULL


------------------------------------------------------------
--  Check if the session user has the essential
-- privilege to update the reference information
------------------------------------------------------------

Declare @ReturnFlag int

Exec SP_UICheckUserPrivilegeRole @UserID , 'Edit References' , @ReturnFlag output

if (@ReturnFlag = 0)
Begin

	set @ErrorDescription = 'Logged User does not have privilege to modify reference details'
	set @ResultFlag = 1
	return 1

End

-----------------------------------------------------------
-- Perform essential validation on the input parameters
-----------------------------------------------------------

if (@ReferenceNo is not NULL)
Begin

	----------------------------------------------------
	-- Check the format of Reference No field
	----------------------------------------------------

	Declare @TempReferenceNo varchar(100)

	set @TempReferenceNo = replace(@ReferenceNo , '/' , '')

	if (( len(@ReferenceNo) - len(@TempReferenceNo)) <> 4) 
	Begin

		set @ErrorDescription = 'Format of the ReferenceNo value is not correct. Allowed format is "Tag/Currency/Service/Traffic Type/Direction"'
		set @ResultFlag = 1
		return 1

	End

	----------------------------------------------------------
	-- Check to ensure that the Reference No is a unique value
	----------------------------------------------------------

	if exists ( select 1 from TB_VendorReferenceDetails where rtrim(ltrim(ReferenceNo)) = rtrim(ltrim(@ReferenceNo)) and ReferenceID <> @ReferenceID)
	Begin

		set @ErrorDescription = 'ReferenceNo is not a unique value. The ReferenceNo already exists in the system.'
		set @ResultFlag = 1
		return 1

	End

End


if ( ( @MultipleSheetsInOffer is not null ) and ( @MultipleSheetsInOffer not in (0,1) ) )
Begin

	set @ErrorDescription = 'Value for MultipleSheetsInOffer configuration is not correct. Allowed values are 0 (No)/1(Yes)'
	set @ResultFlag = 1
	return 1
End

if ( ( @AutoOfferUploadFlag is not null ) and ( @AutoOfferUploadFlag not in (0,1) ) )
Begin

	set @ErrorDescription = 'Value for AutoOfferUploadFlag configuration is not correct. Allowed values are 0 (No)/1(Yes)'
	set @ResultFlag = 1
	return 1
End

if ( ( @SkipRateIncreaseCheck is not null ) and ( @SkipRateIncreaseCheck not in (0,1) ) )
Begin

	set @ErrorDescription = 'Value for SkipRateIncreaseCheck configuration is not correct. Allowed values are 0 (No)/1(Yes)'
	set @ResultFlag = 1
	return 1
End

if ( ( @EnableEmailCheck is not null ) and ( @EnableEmailCheck not in (0,1) ) )
Begin

	set @ErrorDescription = 'Value for EnableEmailCheck configuration is not correct. Allowed values are 0 (No)/1(Yes)'
	set @ResultFlag = 1
	return 1
End


if ( ( @CheckNewDestination is not null ) and ( @CheckNewDestination not in (0,1) ) )
Begin

	set @ErrorDescription = 'Value for CheckNewDestination configuration is not correct. Allowed values are 0 (No)/1(Yes)'
	set @ResultFlag = 1
	return 1
End

----------------------------------------------------------------------
-- Added Change 28th Jan 2013
-- If the new value for EnaleEmailCheck is 1, then one needs to make
-- sure that there exists atleast one authorized sender check in 
-- the system. Other wise it will create the scenafrio where flag
-- is set but there is no Check existing.
----------------------------------------------------------------------

if ( (@EnableEmailCheck = 1) and not exists (select 1 from tblauthorizedemails where referenceid = @ReferenceID ) )
Begin

	set @ErrorDescription = 'Cannot Enable Email Check Flag when there is no authorized sender check configured.'
	set @ResultFlag = 1
	return 1

End

if (( @ParseTemplateName  is not null ) and (len(@ParseTemplateName ) = 0) )
Begin

	set @ParseTemplateName  = NULL

End

if ( @ParseTemplateName is null )
Begin

	set @ErrorDescription = 'Format File Name cannot be empty or NULL'
	set @ResultFlag = 1
	return 1
End

-------------------------------------------------------
-- Adding validation check for Rate Increase Period
-------------------------------------------------------

if ( isnumeric(@RateIncreasePeriod) <> 1 )
Begin

	set @ErrorDescription = 'Value for RateIncreasePeriod configuration is not numeric . Value should be greater than equal to 0'
	set @ResultFlag = 1
	return 1
End

if ( @RateIncreasePeriod < 0 )
Begin

	set @ErrorDescription = 'Value for RateIncreasePeriod configuration is not valid . Value should be greater than equal to 0'
	set @ResultFlag = 1
	return 1
End


-------------------------------------------------------------------
-- Check if any valid reference exists for the passed reference id
-------------------------------------------------------------------

if not exists (  select 1 from tb_vendorreferencedetails where referenceid = @ReferenceID )
Begin

	set @ErrorDescription = 'No reference exists in the BRIDGE system for referenceid : ' + convert(varchar(20) , @ReferenceID)
	set @ResultFlag = 1
	return 1
End


------------------------------------------------------
-- Update the tb_vendorreferencedetails table with the
-- essential information.
------------------------------------------------------

Begin Try

	update tb_vendorreferencedetails
	set ReferenceNo = isnull(@ReferenceNo , ReferenceNo) ,
	    MultipleSheetsInOffer = isnull( @MultipleSheetsInOffer , MultipleSheetsInOffer),
	    ParseTemplateName = isnull(@ParseTemplateName , ParseTemplateName),
	    AutoOfferUploadFlag = isnull(@AutoOfferUploadFlag , AutoOfferUploadFlag),
	    SkipRateIncreaseCheck  = isnull(@SkipRateIncreaseCheck , SkipRateIncreaseCheck),
	    EnableEmailCheck = isnull(@EnableEmailCheck , EnableEmailCheck),
	    RateIncreasePeriod = @RateIncreasePeriod,
		CheckNewDestination = isnull(@CheckNewDestination,CheckNewDestination),
	    ModifiedDate = getdate(),
	    ModifiedByID = @UserID
	where referenceid = @ReferenceID

End Try

Begin Catch

	set @ErrorDescription =  ERROR_MESSAGE()
	set @ResultFlag = 1
	return 1

End Catch
GO
