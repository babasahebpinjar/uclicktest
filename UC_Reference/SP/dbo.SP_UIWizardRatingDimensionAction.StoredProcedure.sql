USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIWizardRatingDimensionAction]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIWizardRatingDimensionAction]
(
	@SessionID varchar(36),
	@DimensionType varchar(100),
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

--------------------------------------------------------------------------------
-- Dimension Type cannot be NULL and has to be either "Date and Time" or "Other"
---------------------------------------------------------------------------------

if (
      ( @DimensionType is NULL )
	  or
	  (rtrim(ltrim(@DimensionType)) not in ('Date and Time' , 'Other') )
   )
Begin

		set @ErrorDescription = 'ERROR !!! Dimension Type is NULL or not a valid value'
		set @ResultFlag = 1
		Return 1


End

---------------------------------------------------------------------------
-- Call the appropriate Validation procedure depending on the dimension type
----------------------------------------------------------------------------

if (rtrim(ltrim(@DimensionType)) = 'Date and Time' )
Begin

		Exec SP_UIWizardRatingDimensionActionDateTime @SessionID , @ErrorDescription Output , @ResultFlag Output

End

if (rtrim(ltrim(@DimensionType)) = 'Other' )
Begin

		Exec SP_UIWizardRatingDimensionActionOthers @SessionID , @ErrorDescription Output , @ResultFlag Output

End

Return 0
GO
