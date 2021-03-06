USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRatingMethodUpdate]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UIRatingMethodUpdate]
(
    @RatingMethodID int,
	@RatingMethod varchar(100),
	@RatingMethodAbbrv varchar(60),
	@UserID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

-------------------------------------------------------------------
-- Make sure that Rate Dimension Template ID is not NULL and Valid
-------------------------------------------------------------------

if ( @RatingMethodID is NULL )
Begin

		set @ErrorDescription = 'ERROR !!! Rating Method ID cannot be NULL'
		set @ResultFlag = 1
		Return 1

End

if not exists (  select 1 from tb_RatingMethod where RatingMethodID = @RatingMethodID and flag & 1 <> 1)
Begin

	set @ErrorDescription = 'ERROR !!! Not a valid Rating Method ID passed as input. Rating Method does not exist'
	set @ResultFlag = 1
	Return 1


End

if exists (  select 1 from tb_RatingMethod where RatingMethodID = @RatingMethodID and RatingMethodID < 0 )
Begin

	set @ErrorDescription = 'ERROR !!! Cannot update information for a default Rating Method. Please contact Administrator'
	set @ResultFlag = 1
	Return 1


End

------------------------------------------------------------------------
-- Make sure that Rating Method name or Abbreviation is not NULL 
------------------------------------------------------------------------

if ( (@RatingMethod is NULL ) or (@RatingMethodAbbrv is NULL ) )
Begin

		set @ErrorDescription = 'ERROR !!! Rating Method Name or Abbreviation cannot be NULL'
		set @ResultFlag = 1
		Return 1

End

-------------------------------------------------------------
-- Ensure that the Rating Method Name is unique and does not 
-- already exist in the system
-------------------------------------------------------------

if exists (select 1 from tb_RatingMethod where ltrim(rtrim(RatingMethod)) = ltrim(rtrim(@RatingMethod)) and RatingMethodID <> @RatingMethodID)
Begin

		set @ErrorDescription = 'ERROR !!! Rating Method already exists in the system by the same name'
		set @ResultFlag = 1
		Return 1

End

-----------------------------------------------------
-- Update rating method record into the database
-----------------------------------------------------

Begin Try

       update tb_RatingMethod
	   set 	RatingMethod = ltrim(rtrim(@RatingMethod)),
			RatingMethodAbbrv = ltrim(rtrim(@RatingMethodAbbrv)),
			ModifiedDate = getdate(),
			ModifiedByID = @UserID
		where RatingMethodID = @RatingMethodID

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!! Updating record for Rating Method. ' + ERROR_MESSAGE()
		set @ResultFlag = 1
		Return 1

End Catch


GO
