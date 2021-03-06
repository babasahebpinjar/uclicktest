USE [UC_Report]
GO
/****** Object:  Table [dbo].[tb_DashboardTrafficAndMarginAnalysis]    Script Date: 5/2/2020 6:38:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_DashboardTrafficAndMarginAnalysis](
	[TrafficMonth] [varchar](10) NULL,
	[TrafficMonthNum] [int] NULL,
	[Minutes] [decimal](19, 2) NULL,
	[Revenue] [decimal](19, 2) NULL,
	[Cost] [decimal](19, 2) NULL,
	[Margin] [decimal](19, 2) NULL
) ON [PRIMARY]
GO
