USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMedDailySanityReport]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_BSMedDailySanityReport]
As

Declare @StartDate date,
		@EndDate date,
		@ExtractFolder varchar(500),
		@ErrorMsgStr varchar(200)

-- Run the report from CURRENT - 1 day

set @StartDate = DateAdd(dd ,-1 , convert(date , getdate()))
set @EndDate = @StartDate

-- Select the Path where the report needs to be extracted

select @ExtractFolder = ConfigValue
from ReferenceServer.UC_Admin.dbo.tb_Config
where configname = 'DailyMediationSanityReportPath'
and AccessScopeID = -9

if ( @ExtractFolder is NULL )
Begin

        set @ExtractFolder = 'ERROR !!!! Daily Mediation Report Path not configured.'
		RaisError( '%s' , 16,1 , @ErrorMsgStr)
		Return 1

End

-- Run the Report for the selected period

Begin Try

		Exec SP_BSMedCustomSanityReport_Axiata @StartDate , @EndDate , @ExtractFolder


End Try

Begin Catch

		set @ErrorMsgStr = 'ERROR !!! While running the mediation sanity report. ' + ERROR_MESSAGE()
		RaisError( '%s' , 16,1 , @ErrorMsgStr)
		Return 1

End Catch

Return 0
GO
