USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIMasterLogExtractStatusList]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UIMasterLogExtractStatusList]
(
	@MasterlogExtractStatusID int = NULL
)
As

Select MasterlogExtractStatusID as ID , MasterlogExtractStatus as Name
from tb_MasterlogExtractStatus
where MasterlogExtractStatusID = isnull(@MasterlogExtractStatusID , MasterlogExtractStatusID)
and Flag & 1 <> 1
Order by MasterlogExtractStatus
GO
