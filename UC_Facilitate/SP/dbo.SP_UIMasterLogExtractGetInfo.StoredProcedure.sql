USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIMasterLogExtractGetInfo]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIMasterLogExtractGetInfo]
(
	@MasterLogExtractID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

----------------------------------------------------------
-- Check if the Masterlog Extract exists in the system or not
----------------------------------------------------------

if not exists ( select 1 from tb_MasterlogExtract where MasterlogExtractId = @MasterLogExtractID )
Begin

		set @ErrorDescription = 'ERROR !!!! Masterlog Extract ID passed as input does not exist in the system'
		set @ResultFlag = 0
		Return 1

End

Begin Try

		Select 
			tbl1.MasterlogExtractID as 'MasterLogExtractID',
			tbl1.MasterlogExtractName as 'MasterLogExtractName',
			tbl3.MasterlogExtractStatus as 'MasterLogExtractStatus',
			tbl2.Name as 'User',
			tbl1.MasterlogExtractFilename as 'MasterLogExtractFileName',
			tbl1.MasterlogExtractRequestDate as 'MasterLogExtractRequestDate',
			tbl1.MasterlogExtractCompletionDate as 'MasterLogExtractCompletionDate',
			tbl1.Remarks as 'Remarks',
			tbl1.ModifiedDate as 'ModifiedDate',
			tbl4.Name as 'ModifiedBy'
		
		from tb_MasterlogExtract tbl1
		inner join REFERENCESERVER.UC_Admin.dbo.tb_Users tbl2
		            on tbl1.UserID = tbl2.UserID
		inner join REFERENCESERVER.UC_Admin.dbo.tb_Users tbl4
		            on tbl1.ModifiedByID = tbl4.UserID
		inner join  tb_MasterlogExtractStatus tbl3
		            on tbl3.MasterlogExtractStatusID = tbl1.MasterlogExtractStatusID
		where tbl1.MasterlogExtractId = @MasterLogExtractID

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!!! While getting Masterlog Extract info. ' + ERROR_MESSAGE()
		set @ResultFlag = 0
		Return 1

End Catch
GO
