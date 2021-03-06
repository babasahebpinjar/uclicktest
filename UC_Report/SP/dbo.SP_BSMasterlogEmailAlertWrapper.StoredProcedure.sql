USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMasterlogEmailAlertWrapper]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE [dbo].[SP_BSMasterlogEmailAlertWrapper]
(
	@EmailSubject varchar(1000),
	@EmailBody varchar(max),
	@ErrorDescription varchar(2000) output,
    @ResultFlag int output
)
AS


set @ErrorDescription = NULL
set @ResultFlag = 0

Exec SP_BSMasterlogEmailAlert @EmailSubject,@EmailBody, @ErrorDescription Output , @ResultFlag Output

Return 0
GO
