USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICDRExtractStatusList]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UICDRExtractStatusList]
(
	@CDRExtractStatusID int = NULL
)
As

Select CDRExtractStatusID as ID , CDRExtractStatus as Name
from tb_CDRExtractStatus
where CDRExtractStatusID = isnull(@CDRExtractStatusID , CDRExtractStatusID)
and Flag & 1 <> 1
Order by CDRExtractStatus
GO
