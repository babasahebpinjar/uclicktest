USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRateDimensionBandUpdate]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_UIRateDimensionBandUpdate]
(
    @RateDimensionBandID int,
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

if ( @RateDimensionBandID is NULL )
Begin

		set @ErrorDescription = 'ERROR !!! Rate Dimension Band ID cannot be NULL'
		set @ResultFlag = 1
		Return 1

End

if not exists (  select 1 from tb_RateDimensionBand where RateDimensionBandID = @RateDimensionBandID and flag & 1 <> 1)
Begin

	set @ErrorDescription = 'ERROR !!! Not a valid Rate Dimension Band ID passed as input. Rate Dimension Band does not exist'
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

Declare @RateDimensionTemplateID int

Select @RateDimensionTemplateID = RateDimensionTemplateID
from tb_RateDimensionBand
where RateDimensionBandID = @RateDimensionBandID

if (  @RateDimensionTemplateID < 0 )
Begin

	set @ErrorDescription = 'ERROR !!! Cannot update information for a default dimension Template. Please contact Administrator'
	set @ResultFlag = 1
	Return 1


End

if exists (  select 1 from tb_RateDimensionBand where rtrim(ltrim(RateDimensionBand)) = rtrim(ltrim(@RateDimensionBand)) and RateDimensionTemplateID = @RateDimensionTemplateID and RateDimensionBandID <> @RateDimensionBandID)
Begin

	set @ErrorDescription = 'ERROR !!! Rate Dimension band already exist by the name : (' + @RateDimensionBand + ')'
	set @ResultFlag = 1
	Return 1


End

---------------------------------------------------------
-- Update record in the database for new Dimension Band
---------------------------------------------------------

Begin Try

	update tb_RateDimensionBand
	set RateDimensionBand =  @RateDimensionBand,
	    RateDimensionBandAbbrv = @RateDimensionBandAbbrv,
		ModifiedDate = GetDate(),
		ModifiedByID = @UserID
	where RateDimensionBandID = @RateDimensionBandID

End Try


Begin Catch

	set @ErrorDescription = 'ERROR !!! Updating Dimension Band record. '+ ERROR_MESSAGE()
	set @ResultFlag = 1
	Return 1


End Catch

Return 0
GO
