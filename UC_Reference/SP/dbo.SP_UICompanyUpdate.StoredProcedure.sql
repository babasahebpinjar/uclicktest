USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICompanyUpdate]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     PROCEDURE [dbo].[SP_UICompanyUpdate]
  (
    @ComapnyID int,
	@Company varchar(60),
	@UserID int,
	@ErrorDescription varchar(200) Output,
	@ResultFlag int Output
  )

AS

set @ResultFlag = 0
set  @ErrorDescription = NULL

Begin Try

    update tb_company
	set company = @Company,
	    modifiedDate = getdate(),
		ModifiedByID = @UserID
	where companyid = @ComapnyID

End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!! While updating exisitng company record. '+ ERROR_MESSAGE()
	set @ResultFlag = 1
	Return 1

End Catch


Return 0
















GO
