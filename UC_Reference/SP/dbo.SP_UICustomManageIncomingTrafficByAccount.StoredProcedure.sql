USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICustomManageIncomingTrafficByAccount]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_UICustomManageIncomingTrafficByAccount]
(
	@AccountID int,
	@TaskFlag int, -- 0 means Unblock , 1 means Block
	@ReasonDesc varchar(200), -- Reason for action being performed
	@UserID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ResultFlag = 0
set @ErrorDescription = NULL


------------------------------------------------------------------------
-- Now Call the Procedure for Blocking the incoming traffic for Account
------------------------------------------------------------------------

Begin Try

	set @ErrorDescription = NULL
	set @ResultFlag = 0

	Exec SP_BSCustomManageIncomingTrafficByAccountMain @AccountID, @TaskFlag, @ReasonDesc , @UserID ,
													   @ErrorDescription Output, @ResultFlag Output

	if (@ResultFlag  = 1)
	Begin

			Return 1

	End

End Try

Begin Catch

			set @ErrorDescription = ERROR_MESSAGE()			          
			set @ResultFlag = 1
			Return 1

End Catch


Return 0
GO
