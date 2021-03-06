USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIDeleteExceptionCheckDetails]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIDeleteExceptionCheckDetails] 
(
    @ExceptionCheckID		int,
    @UserID                     int,
    @ResultFlag			int Output,
    @ErrorDescription		varchar(500) Output
)
--With Encryption
As

set @ResultFlag	= 0

------------------------------------------------------------
--  Check if the session user has the essential
-- privilege to delete the Authorized Sender information
------------------------------------------------------------

Declare @ReturnFlag int

Exec SP_UICheckUserPrivilegeRole @UserID , 'Delete Exception Check' , @ReturnFlag output

if (@ReturnFlag = 0)
Begin

	set @ErrorDescription = 'Logged User does not have privilege to delete Exception Check Details'
	set @ResultFlag = 1
	return

End

if ( (@ExceptionCheckID is NULL) or not exists ( select 1 from tblVendorEmailDetails where ID = @ExceptionCheckID))
Begin

	set @ErrorDescription = 'The Exception Check requested for Deletion does not exist or passed ID value is NULL'
	set @ResultFlag = 1
	return

End

Begin Try

	Delete From tblVendorEmailDetails
	where ID = @ExceptionCheckID


End Try


Begin Catch

	set @ResultFlag = 1
	set @ErrorDescription = ERROR_MESSAGE()
	return

End Catch
GO
