USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSCustomManageIncomingTrafficByTrunkMain]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Procedure [dbo].[SP_BSCustomManageIncomingTrafficByTrunkMain]
(
	@TrunkIDList nvarchar(max),
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
-- Now Call the Procedure for Blocking the incoming traffic for Trunk
------------------------------------------------------------------------

Begin Try

	set @ErrorDescription = NULL
	set @ResultFlag = 0

	Exec SP_BSCustomManageIncomingTrafficByTrunk @TrunkIDList, @TaskFlag, @ReasonDesc , @UserID ,
												 @ErrorDescription Output, @ResultFlag Output

	if (@ResultFlag  = 1)
	Begin

			set @ErrorDescription = 'Error!!! '+
			                         Case When @TaskFlag = 0 Then 'UnBlocking' Else 'Blocking' End +
			                        ' incoming traffic for trunks(s). ' + @ErrorDescription
			GOTO ENDPROCESS

	End

End Try

Begin Catch

			set @ErrorDescription = 'Error!!! '+
			                         Case When @TaskFlag = 0 Then 'UnBlocking' Else 'Blocking' End +
			                        ' incoming traffic for trunk(s). ' + ERROR_MESSAGE()
			          
			set @ResultFlag = 1
			GOTO ENDPROCESS

End Catch


---------------------------------------------------------------------------------------
-- Call Procedure to send the Email alert regarding the blocking/UnBlocking of trunk
---------------------------------------------------------------------------------------
Begin Try


	Exec SP_BSTRafficManageByTrunkEmail @TrunkIDList , @ReasonDesc , @TaskFlag , @UserID


End Try

Begin Catch

			set @ErrorDescription = 'Error!!! While sending email for '+
			                         Case When @TaskFlag = 0 Then 'UnBlocking' Else 'Blocking' End +
			                        ' incoming traffic for trunk(s). ' + ERROR_MESSAGE()
			set @ResultFlag = 1
			GOTO ENDPROCESS

End Catch




ENDPROCESS:

Return 0
GO
