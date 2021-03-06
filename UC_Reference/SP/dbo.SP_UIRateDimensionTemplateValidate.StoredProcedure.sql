USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRateDimensionTemplateValidate]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRateDimensionTemplateValidate]
(
	@RateDimensionTemplateID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

-------------------------------------------------------------------
-- Make sure that Rate Dimension Template ID is not NULL and Valid
-------------------------------------------------------------------

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

-----------------------------------------------------------------------------
-- Ensure that the Rate Dimension Template has Dimension Bands associated
-- with it
------------------------------------------------------------------------------

if not exists ( select 1 from tb_RateDimensionBand where RateDimensionTemplateID = @RateDimensionTemplateID )
Begin

	set @ErrorDescription = 'ERROR !!! Rate Dimension Template configuration is not complete. Missing Dimension Band info'
	set @ResultFlag = 1
	Return 1

End

--------------------------------------------------------------------
-- Check that the band details are defined as per the dimension type
-- In case of date time dimensions the 
--------------------------------------------------------------------

Declare @RateDimensionID int

select @RateDimensionID = RateDimensionID
from tb_RateDimensionTemplate
where RateDimensionTemplateID = @RateDimensionTemplateID

if ( @RateDimensionID = 1 ) -- Date time band 
Begin

	if not exists (
						select 1 
						from tb_DateTimeBandDetail tbl1
						inner join tb_RateDimensionBand tbl2 on tbl1.DateTimeBandID = tbl2.RateDimensionBandID
						where tbl2.RateDimensionTemplateID = @RateDimensionTemplateID
	              )
	Begin

			set @ErrorDescription = 'ERROR !!! Rate Dimension Template configuration is not complete. Dimension Bands exist without any band details'
			set @ResultFlag = 1
			Return 1

	End
	


End

Else
Begin

	if not exists (
						select 1 
						from tb_RateDimensionBandDetail tbl1
						inner join tb_RateDimensionBand tbl2 on tbl1.RateDimensionBandID = tbl2.RateDimensionBandID
						where tbl2.RateDimensionTemplateID = @RateDimensionTemplateID
	              )
	Begin

						set @ErrorDescription = 'ERROR !!! Rate Dimension Template configuration is not complete. Dimension Bands exist without any band details'
			set @ResultFlag = 1
			Return 1

	End

End

return 0
GO
