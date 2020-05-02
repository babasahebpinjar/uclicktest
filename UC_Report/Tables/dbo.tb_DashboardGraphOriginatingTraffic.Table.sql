USE [UC_Report]
GO
/****** Object:  Table [dbo].[tb_DashboardGraphOriginatingTraffic]    Script Date: 5/2/2020 6:38:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_DashboardGraphOriginatingTraffic](
	[CallDate] [datetime] NULL,
	[ServiceLevel] [varchar](100) NULL,
	[TotalMinutes] [decimal](19, 2) NULL
) ON [PRIMARY]
GO
