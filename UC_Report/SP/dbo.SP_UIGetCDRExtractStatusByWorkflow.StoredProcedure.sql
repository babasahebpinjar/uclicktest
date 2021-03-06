USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetCDRExtractStatusByWorkflow]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UIGetCDRExtractStatusByWorkflow]
(
	@CDRExtractID int
)
As

Declare @CDRExtractCurrentStatusID int

--------------------------------------------------------
-- Get the current status of the CDR Extract from schema
--------------------------------------------------------

Select @CDRExtractCurrentStatusID = CDRExtractStatusID
From tb_CDRExtract
where CDRExtractID = @CDRExtractID


--------------------------------------------------------
-- Check the next permissible status(es) for the Extract
-- from the workflow schema
---------------------------------------------------------

Select tbl2.CDRExtractStatusID as ID , tbl2.CDRExtractStatus as Name
from tb_CDRExtractStatusWorkflow tbl1
inner join tb_CDRExtractStatus tbl2 on tbl1.ToCDRExtractStatusID = tbl2.CDRExtractStatusID
where tbl1.FromCDRExtractStatusID = @CDRExtractCurrentStatusID
order by tbl2.CDRExtractStatus

Return 0
GO
