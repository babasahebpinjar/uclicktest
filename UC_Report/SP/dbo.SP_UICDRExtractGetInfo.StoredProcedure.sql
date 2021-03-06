USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICDRExtractGetInfo]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UICDRExtractGetInfo]
(
	@CDRExtractID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

----------------------------------------------------------
-- Check if the CDR Extract exists in the system or not
----------------------------------------------------------

if not exists ( select 1 from tb_CDRExtract where CDRExtractID = @CDRExtractID )
Begin

		set @ErrorDescription = 'ERROR !!!! CDR Extract ID passed as input does not exist in the system'
		set @ResultFlag = 0
		Return 1

End

Begin Try

		Select tbl1.CDRExtractID , tbl1.CDRExtractName,
		       tbl4.CDRExtractStatus , tbl2.Name as 'User',
			   tbl1.CDRExtractFileName , tbl1.CDRExtractRequestDate,
			   tbl1.CDRExtractCompletionDate, 
			   tbl1.Remarks,
			   tbl1.ModifiedDate,
			   tbl3.Name as ModifiedBy
		from tb_CDRExtract tbl1
		inner join REFERENCESERVER.UC_Admin.dbo.tb_Users tbl2
		               on tbl1.UserID = tbl2.UserID
		inner join REFERENCESERVER.UC_Admin.dbo.tb_Users tbl3
		               on tbl1.ModifiedByID = tbl3.UserID
        inner join tb_CDRExtractStatus tbl4
		               on tbl1.CDRExtractStatusID = tbl4.CDRExtractStatusID
		where tbl1.CDRExtractID = @CDRExtractID

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!!! While getting CDR Extract info. ' + ERROR_MESSAGE()
		set @ResultFlag = 0
		Return 1

End Catch
GO
