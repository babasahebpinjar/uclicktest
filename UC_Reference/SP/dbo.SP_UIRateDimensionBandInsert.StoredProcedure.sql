USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRateDimensionBandInsert]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_UIRateDimensionBandInsert]
(
	@RateDimensionTemplateID int,
	@RateDimensionBand varchar(100),
	@RateDimensionBandAbbrv varchar(60),
	@UserID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

---------------------------------------------------------------------
-- Rate Dimension Template ID should not be NULL and have valid value
---------------------------------------------------------------------

if ( @RateDimensionTemplateID is NULL )
Begin

		set @ErrorDescription = 'ERROR !!! Rate Dimension Template ID cannot be NULL'
		set @ResultFlag = 1
		Return 1

End

if not exists (  select 1 from tb_RateDimensionTemplate where RateDimensionTemplateID = @RateDimensionTemplateID and flag & 1 <> 1)
Begin

	set @ErrorDescription = 'ERROR !!! Not a valid Rate Dimension Template ID passed as input. Rate Dimension Template does not exist'
	set @ResultFlag = 1
	Return 1


End

if exists (  select 1 from tb_RateDimensionTemplate where RateDimensionTemplateID = @RateDimensionTemplateID and RateDimensionTemplateID < 0 )
Begin

	set @ErrorDescription = 'ERROR !!! Cannot update information for a default dimension Template. Please contact Administrator'
	set @ResultFlag = 1
	Return 1


End

-------------------------------------------------------------------------------
-- Make sure that RateDimensionBand and RateDimensionBandAbbrv are not NULL
-------------------------------------------------------------------------------

if ( ( @RateDimensionBand is NULL ) or ( @RateDimensionBandAbbrv is NULL ) )
Begin

	set @ErrorDescription = 'ERROR !!! Rate Dimension band name or Abbreviation cannot be NULL' 
	set @ResultFlag = 1
	Return 1

End

------------------------------------------------------------------------------
-- Check if no other dimension band exists under the template by the same name
------------------------------------------------------------------------------

if exists (  select 1 from tb_RateDimensionBand where rtrim(ltrim(RateDimensionBand)) = rtrim(ltrim(@RateDimensionBand)) and RateDimensionTemplateID = @RateDimensionTemplateID)
Begin

	set @ErrorDescription = 'ERROR !!! Rate Dimension band already exist by the name : (' + @RateDimensionBand + ')'
	set @ResultFlag = 1
	Return 1


End

---------------------------------------------------------
-- Insert record in the database for new Dimension Band
---------------------------------------------------------

Begin Try

	insert into tb_RateDimensionBand
	(
		RateDimensionBand,
		RateDimensionBandAbbrv,
		RateDimensionTemplateID,
		ModifiedDate,
		ModifiedByID,
		Flag
	)
	Values
	(
		@RateDimensionBand,
		@RateDimensionBandAbbrv,
		@RateDimensionTemplateID,
		Getdate(),
		@UserID,
		0
	)

End Try


Begin Catch

	set @ErrorDescription = 'ERROR !!! Inserting new Dimension Band record. '+ ERROR_MESSAGE()
	set @ResultFlag = 1
	Return 1


End Catch

Return 0
GO
