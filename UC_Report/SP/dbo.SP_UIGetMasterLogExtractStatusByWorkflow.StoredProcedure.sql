USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetMasterLogExtractStatusByWorkflow]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UIGetMasterLogExtractStatusByWorkflow]
(
	@MasterLogExtractID int
)
As

Declare @MasterLogExtractCurrentStatusID int

--------------------------------------------------------
-- Get the current status of the Master Log Extract from schema
--------------------------------------------------------

Select @MasterLogExtractCurrentStatusID = MasterlogExtractStatusID
From tb_MasterlogExtract
where MasterlogExtractId = @MasterLogExtractID


--------------------------------------------------------
-- Check the next permissible status(es) for the Extract
-- from the workflow schema
---------------------------------------------------------

Select tbl2.MasterlogExtractStatusID as ID , tbl2.MasterlogExtractStatus as Name
from tb_MasterLogExtractStatusWorkflow tbl1
inner join tb_MasterLogExtractStatus tbl2 on tbl1.ToMasterlogExtractStatusID = tbl2.MasterlogExtractStatusID
where tbl1.FromMasterlogExtractStatusID = @MasterLogExtractCurrentStatusID
order by tbl2.MasterlogExtractStatus

Return 0
GO
