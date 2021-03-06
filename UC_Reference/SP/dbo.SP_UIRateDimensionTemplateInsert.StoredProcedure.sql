USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRateDimensionTemplateInsert]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRateDimensionTemplateInsert]
(
	@RateDimensionID int,
	@RateDimensionTemplate varchar(100),
	@UserID int,
	@RateDimensionTemplateID int Output,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0
set @RateDimensionTemplateID = NULL

-------------------------------------------------------------------
-- Make sure that Rate Dimension Template ID is not NULL and Valid
-------------------------------------------------------------------

if ( @RateDimensionID is NULL )
Begin

		set @ErrorDescription = 'ERROR !!! Rate Dimension Template ID cannot be NULL'
		set @ResultFlag = 1
		Return 1

End

if not exists (  select 1 from tb_RateDimension where RateDimensionID = @RateDimensionID and flag & 1 <> 1)
Begin

	set @ErrorDescription = 'ERROR !!! Not a valid Rate Dimension ID passed as input. Rate Dimension does not exist'
	set @ResultFlag = 1
	Return 1


End

if exists (  select 1 from tb_RateDimensionTemplate where rtrim(ltrim(RateDimensionTemplate)) = rtrim(ltrim(@RateDimensionTemplate)))
Begin

	set @ErrorDescription = 'ERROR !!! Rate Dimension template already exists by the name : (' + @RateDimensionTemplate + ')'
	set @ResultFlag = 1
	Return 1


End


------------------------------------------------------
-- Insert the Rate Dimension Template Data in the DB
------------------------------------------------------

Begin Try

	insert into tb_RateDimensionTemplate
	(
		RateDimensionTemplate,
		RateDimensionID,
		ModifiedDate,
		ModifiedByID,
		Flag	
	)
	values
	(
		rtrim(ltrim(@RateDimensionTemplate)),
		@RateDimensionID,
		GETDATE(),
		@UserID,
		0
	)

	set @RateDimensionTemplateID = @@IDENTITY -- ID of the newly created Rate Dimension Template

End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!! While inserting new Rate Dimension Template record. '+ ERROR_MESSAGE()
	set @ResultFlag = 1
	Return 1

End Catch



GO
