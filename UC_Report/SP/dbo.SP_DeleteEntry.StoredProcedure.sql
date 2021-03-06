USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_DeleteEntry]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================

CREATE Procedure [dbo].[SP_DeleteEntry]
(
     @LogDateInput varchar(100),
	 @ResultFlag int Output,
     @ErrorDescription varchar(200) Output
)


AS
set @ErrorDescription = NULL
set @ResultFlag = 0



--------------------------------
-- Update the user information
--------------------------------

SET NOCOUNT ON

Begin Try

  delete from tb_LogEntries
  where LogDate <= convert(datetime,@LogDateInput)

End Try

Begin Catch

	set @ErrorDescription = ERROR_MESSAGE()
	set @ResultFlag = 1
	return

End Catch

Return
GO
