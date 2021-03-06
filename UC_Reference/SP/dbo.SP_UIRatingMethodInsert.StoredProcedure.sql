USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRatingMethodInsert]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRatingMethodInsert]
(
	@RatingMethod varchar(100),
	@RatingMethodAbbrv varchar(60),
	@RateStructureID int,
	@UserID int,
	@RatingMethodID int Output,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

------------------------------------------------------------------------
-- Make sure that Rating Method name or Abbreviation is not NULL 
------------------------------------------------------------------------

if ( (@RatingMethod is NULL ) or (@RatingMethodAbbrv is NULL ) )
Begin

		set @ErrorDescription = 'ERROR !!! Rating Method Name or Abbreviation cannot be NULL'
		set @ResultFlag = 1
		Return 1

End

-----------------------------------------------------------
-- Check that the rate structure ID exists in the system
-----------------------------------------------------------

if ( 
		(@RateStructureID is NULL )
		or
		not exists ( select 1 from tb_RateStructure where RateStructureID = @RateStructureID )
   )
Begin

		set @ErrorDescription = 'ERROR !!! Rate Structure ID passed is NULL or does not exist in the system'
		set @ResultFlag = 1
		Return 1

End

-------------------------------------------------------------
-- Ensure that the Rating Method Name is unique and does not 
-- already exist in the system
-------------------------------------------------------------

if exists (select 1 from tb_RatingMethod where ltrim(rtrim(RatingMethod)) = ltrim(rtrim(@RatingMethod)))
Begin

		set @ErrorDescription = 'ERROR !!! Rating Method already exists in the system by the same name'
		set @ResultFlag = 1
		Return 1

End

-----------------------------------------------------
-- Insert new rating method record into the database
-----------------------------------------------------

Begin Try

		insert into tb_RatingMethod
		(
			RatingMethod,
			RatingMethodAbbrv,
			RateStructureID,
			ModifiedDate,
			ModifiedByID,
			Flag
		)
		Values
		(
			ltrim(rtrim(@RatingMethod)),
			ltrim(rtrim(@RatingMethodAbbrv)),
			@RateStructureID,
			Getdate(),
			@UserID,
			0
		)

		set @RatingMethodID = @@IDENTITY -- ID of the newly created Rating Method


End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!! Inserting new record for Rating Method. ' + ERROR_MESSAGE()
		set @ResultFlag = 1
		Return 1

End Catch


GO
