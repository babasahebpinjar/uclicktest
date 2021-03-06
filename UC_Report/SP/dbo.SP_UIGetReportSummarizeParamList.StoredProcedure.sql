USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetReportSummarizeParamList]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetReportSummarizeParamList]
(
	@ReportID int
)
As

select  tbl3.RptSummarizeParameterValue as ID , tbl3.RptSummarizeParameterName as Name
from tb_Report tbl1
inner join tb_ReportParam tbl2 on tbl1.ReportID = tbl2.ReportID
inner join tb_RptSummarizeParameter tbl3 on tbl2.ParameterID = tbl3.RptSummarizeParameterID
where tbl1.ReportID = @ReportID
and tbl1.Flag & 1 <> 1
and tbl2.Flag & 1 <> 1
and tbl3.Flag & 1  <> 1
and tbl2.ParamType = 'Summarize'

Return 0
GO
