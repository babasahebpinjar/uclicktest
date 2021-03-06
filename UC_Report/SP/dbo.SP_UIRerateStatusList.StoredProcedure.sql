USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRerateStatusList]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRerateStatusList]
(
	@RerateStatusID int = NULL
)
As

Select RerateStatusID as ID , RerateStatus as Name
from tb_RerateStatus
where RerateStatusID = isnull(@RerateStatusID , RerateStatusID)
and Flag & 1 <> 1
Order by RerateStatus
GO
