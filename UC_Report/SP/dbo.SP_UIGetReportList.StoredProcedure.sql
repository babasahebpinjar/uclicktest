USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetReportList]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UIGetReportList]
As

select tbl1.ReportCategoryID , tbl2.ReportCategory , tbl1.ReportID , tbl1.ReportName
from tb_Report tbl1
inner join tb_ReportCategory tbl2 on tbl1.ReportCategoryID = tbl2.ReportCategoryID
where tbl1.Flag & 1 <> 1
and tbl2.Flag & 1 <> 1

Return 0
GO
