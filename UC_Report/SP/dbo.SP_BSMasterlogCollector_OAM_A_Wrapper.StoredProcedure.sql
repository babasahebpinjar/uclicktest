USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMasterlogCollector_OAM_A_Wrapper]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_BSMasterlogCollector_OAM_A_Wrapper]
AS

Declare @ErrorDescription varchar(2000),
        @ResultFlag int

set @ErrorDescription = NULL
set @ResultFlag = 0

Exec SP_BSMasterlogCollector_OAM_A @ErrorDescription Output , @ResultFlag Output

Return 0
GO
