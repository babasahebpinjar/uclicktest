USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIMasterlogExtractGetParameterList]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Procedure [dbo].[SP_UIMasterlogExtractGetParameterList]
(
	@MasterlogExtractID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

----------------------------------------------------------
-- Check if the Masterlog Extract exists in the system or not
----------------------------------------------------------

if not exists ( select 1 from tb_MasterlogExtract where MasterlogExtractID = @MasterlogExtractID )
Begin

		set @ErrorDescription = 'ERROR !!!! Masterlog Extract ID passed as input does not exist in the system'
		set @ResultFlag = 0
		Return 1

End

Begin Try

		Select tbl1.MasterlogExtractID , 
			   tbl1.CallID,
			   tbl1.CallingNumber,
			   tbl1.CalledNumber,
			   tbl1.ModifiedDate,
			   tbl2.Name as ModifiedBy
		from tb_MasterlogExtractParamList tbl1
		inner join REFERENCESERVER.UC_Admin.dbo.tb_Users tbl2
		               on tbl1.ModifiedByID = tbl2.UserID
		where tbl1.MasterlogExtractID = @MasterlogExtractID

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!!! While getting Masterlog Extract Parameter List. ' + ERROR_MESSAGE()
		set @ResultFlag = 0
		Return 1

End Catch
GO
