USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRerateGetParameterList]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRerateGetParameterList]
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

		Select tbl1.RerateID , 
			   tbl1.BeginDate,
			   tbl1.EndDate,
			   tbl1.CallTypeID,
			   tbl1.INAccountList,
			   tbl1.OUTAccountList,
			   tbl1.INCommercialTrunkList,
			   tbl1.OUTCommercialTrunkList,
			   tbl1.INTechnicalTrunkList,
			   tbl1.OUTTechnicalTrunkList,
			   tbl1.CountryList,
			   tbl1.DestinationList,
			   tbl1.ServiceLevelList,
			   tbl1.ConditionClause,
		       tbl1.ModifiedDate,
			   tbl2.Name as ModifiedBy
		from tb_RerateParamList tbl1
		inner join REFERENCESERVER.UC_Admin.dbo.tb_Users tbl2
		               on tbl1.ModifiedByID = tbl2.UserID
		where tbl1.RerateID = @RerateID

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!!! While getting Rerate job Parameter List. ' + ERROR_MESSAGE()
		set @ResultFlag = 0
		Return 1

End Catch
GO
