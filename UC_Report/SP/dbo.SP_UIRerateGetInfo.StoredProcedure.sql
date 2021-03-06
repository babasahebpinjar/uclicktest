USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRerateGetInfo]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRerateGetInfo]
(
	@RerateID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

----------------------------------------------------------
-- Check if the CDR Extract exists in the system or not
----------------------------------------------------------

if not exists ( select 1 from tb_Rerate where RerateID = @RerateID )
Begin

		set @ErrorDescription = 'ERROR !!!! Rerate ID passed as input does not exist in the system'
		set @ResultFlag = 0
		Return 1

End

Begin Try

		Select tbl1.RerateID , tbl1.RerateName,
		       tbl4.RerateStatus , tbl2.Name as 'User',
               tbl1.RerateRequestDate,
			   tbl1.RerateCompletionDate, 
			   tbl1.Remarks,
			   tbl1.ModifiedDate,
			   tbl3.Name as ModifiedBy
		from tb_Rerate tbl1
		inner join REFERENCESERVER.UC_Admin.dbo.tb_Users tbl2
		               on tbl1.UserID = tbl2.UserID
		inner join REFERENCESERVER.UC_Admin.dbo.tb_Users tbl3
		               on tbl1.ModifiedByID = tbl3.UserID
        inner join tb_RerateStatus tbl4
		               on tbl1.RerateStatusID = tbl4.RerateStatusID
		where tbl1.RerateID = @RerateID

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!!! While getting Rerate job info. ' + ERROR_MESSAGE()
		set @ResultFlag = 0
		Return 1

End Catch
GO
