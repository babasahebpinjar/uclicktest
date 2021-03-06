USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRateDimensionTemplateUpdate]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRateDimensionTemplateUpdate]
(
	@RateDimensionTemplateID int,
	@RateDimensionTemplate varchar(100),
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

if exists (  select 1 from tb_RateDimensionTemplate where rtrim(ltrim(RateDimensionTemplate)) = rtrim(ltrim(@RateDimensionTemplate)) and RateDimensionTemplateID <> @RateDimensionTemplateID)
Begin

	set @ErrorDescription = 'ERROR !!! Rate Dimension template already exist by the name : (' + @RateDimensionTemplate + ')'
	set @ResultFlag = 1
	Return 1


End


------------------------------------------------------
-- Update the Rate Dimension Template Data in the DB
------------------------------------------------------

Begin Try

	update tb_RateDimensionTemplate
	set RateDimensionTemplate = Rtrim(ltrim(@RateDimensionTemplate)),
	ModifiedDate = Getdate(),
	ModifiedByID = @UserID
	where RateDimensionTemplateID = @RateDimensionTemplateID


End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!! While updating Rate Dimension Template. '+ ERROR_MESSAGE()
	set @ResultFlag = 1
	Return 1

End Catch



GO
