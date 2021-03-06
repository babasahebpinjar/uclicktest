USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRatingMethodInsertFromSource]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRatingMethodInsertFromSource]
(
	@RatingMethod varchar(100),
	@RatingMethodAbbrv varchar(60),
	@RatingMethodSourceID int,
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

---------------------------------------------------------------
-- Check that the source rating method ID exists in the system
---------------------------------------------------------------

if ( 
		(@RatingMethodSourceID is NULL )
		or
		not exists ( select 1 from tb_RatingMethod where RatingMethodID = @RatingMethodSourceID )
   )
Begin

		set @ErrorDescription = 'ERROR !!! Source Rating Method ID passed is NULL or does not exist in the system'
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


-----------------------------------------------------------
-- Copy all the data from the source rating method and 
-- insert in the system for target rating method
-----------------------------------------------------------

Begin Transaction InsRM

Begin Try

		-------------------------
		-- tb_RatingMethod
		-------------------------

		insert into tb_RatingMethod
		(
			RatingMethod,
			RatingMethodAbbrv,
			RateStructureID,
			ModifiedDate,
			ModifiedByID,
			Flag
		)
		Select ltrim(rtrim(@RatingMethod)),
			   ltrim(rtrim(@RatingMethodAbbrv)),
			   RateStructureID,
			   Getdate(),
			   @UserID,
			   0
		from tb_RatingMethod
		where RatingMethodID = @RatingMethodSourceID
			   
		set @RatingMethodID = @@IDENTITY -- ID of the newly created Rating Method


		-----------------------------
		-- tb_RatingMethodDetail
		-----------------------------

		insert into tb_RatingmethodDetail
		( 
		   RatingMethodID ,
		   Number , 
		   ItemValue , 
		   RateItemID , 
		   ModifiedDate , 
		   ModifiedByID , 
		   Flag
	    )
		Select @RatingMethodID ,
		      Number , 
		      ItemValue , 
		      RateItemID , 
			  getdate() , 
			  @UserID , 
			  0
		From tb_RatingmethodDetail
		where RatingMethodID = @RatingMethodSourceID


		-----------------------------
		-- tb_RateNumberIdentifier
		-----------------------------

		insert into tb_RateNumberIdentifier
		(
			RateDimension1BandID ,
			RateDimension2BandID ,
			RateDimension3BandID ,
			RateDimension4BandID ,
			RateDimension5BandID ,
			RatingMethodID ,
			RateItemID ,
			ModifiedByID,
			ModifiedDate,
			Flag 
		)
		select
			RateDimension1BandID ,
			RateDimension2BandID ,
			RateDimension3BandID ,
			RateDimension4BandID ,
			RateDimension5BandID ,
			@RatingMethodID ,
			RateItemID ,
			@UserID,
			GetDate(),
			0 
		from tb_RateNumberIdentifier
		where RatingMethodID = @RatingMethodSourceID

		  
End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!! Inserting new record for Rating Method from source. ' + ERROR_MESSAGE()
		set @ResultFlag = 1
		Rollback Transaction InsRM
		Return 1

End Catch

Commit Transaction InsRM


GO
