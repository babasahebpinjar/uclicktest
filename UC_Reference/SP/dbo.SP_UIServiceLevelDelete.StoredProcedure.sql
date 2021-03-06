USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIServiceLevelDelete]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIServiceLevelDelete]
(
	@ServiceLevelID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

if exists ( select 1 from tb_AgreementSL where ServiceLevelID = @ServiceLevelID )
Begin

		set @ErrorDescription = 'ERROR !!! Cannot delete service level record as it is associated to one or more service level assignments '
		set @ResultFlag = 1
		return 1

End

Begin Try

	Delete from tb_ServiceLevel
	where ServiceLevelID = @ServiceLevelID

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!! Deleting Service Level record .' + ERROR_MESSAGE()
		set @ResultFlag = 1
		return 1

End Catch

return 0
GO
