USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICompanyInsert]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_UICompanyInsert]
  (
	@Company varchar(60),
	@UserID int,
	@ErrorDescription varchar(200) Output,
	@ResultFlag int Output
  )

AS

set @ResultFlag = 0
set  @ErrorDescription = NULL

Begin Try

	INSERT INTO tb_Company
	(
		[Company],
		[ModifiedDate],
		[ModifiedByID],
		[Flag]
	)
	VALUES
	(
		@Company,
		GetDate(),
		@UserID,
		0
	)

End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!! While creating new company record. ' + char(10) + ERROR_MESSAGE()
	set @ResultFlag = 1
	Return 1
	
End Catch


Return 0
















GO
