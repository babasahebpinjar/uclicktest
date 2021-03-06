USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIMasterlogExtractUpdateParameterList]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Procedure [dbo].[SP_UIMasterlogExtractUpdateParameterList]
(
    @MasterlogExtractID int,
	@UserID int,
    @CallID varchar(max),
    @CallingNumber varchar(max),
    @CalledNumber varchar(max),
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

----------------------------------------------------------
-- Check to see if the User ID is valid and is active
----------------------------------------------------------

if not exists ( select 1 from ReferenceServer.UC_Admin.dbo.tb_Users where UserID = @UserID and UserstatusID = 1 )
Begin

		set @ErrorDescription = 'ERROR !!!! User ID passed for extract creation does not exist or is inactive'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End

--------------------------------------------------------------------------------
-- Check to see that there does not exist another Masterlog Extract with the same name
-- for the user
---------------------------------------------------------------------------------

if not exists ( select 1 from tb_MasterlogExtract where MasterlogExtractID = @MasterlogExtractID and UserID = @UserID )
Begin

		set @ErrorDescription = 'ERROR !!!! There is no extract in the system for the passed Extract and User ID'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End





Declare @MasterlogExtractStatusID int

Select @MasterlogExtractStatusID = MasterlogExtractStatusID
from tb_MasterlogExtract
where MasterlogExtractID = @MasterlogExtractID

if ( @MasterlogExtractStatusID not in (-1, -4, -5) )
Begin

			set @ErrorDescription = 'ERROR !!! Update to Masterlog Extract Parameter List only allowed in Registered , Failed or Cancelled state'
			set @ResultFlag = 1
			GOTO ENDPROCESS

End

Begin Try

            Update tb_MasterlogExtractParamList
			set CallID                 = @CallID,
				CallingNumber          = @CallingNumber,
				CalledNumber           = @CalledNumber, 
				ModifiedDate           = GetDate(),
				ModifiedByID           = @UserID 
            where MasterlogExtractID = @MasterlogExtractID
			
			

End Try

Begin Catch

			set @ErrorDescription = 'ERROR !!! While updating parameter list for Masterlog extract. ' + ERROR_MESSAGE()
			set @ResultFlag = 1

			GOTO ENDPROCESS

End Catch


ENDPROCESS:
GO
