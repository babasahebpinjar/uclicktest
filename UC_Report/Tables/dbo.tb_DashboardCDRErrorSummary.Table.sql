USE [UC_Report]
GO
/****** Object:  Table [dbo].[tb_DashboardCDRErrorSummary]    Script Date: 5/2/2020 6:38:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_DashboardCDRErrorSummary](
	[ErrorType] [varchar](100) NULL,
	[Direction] [varchar](100) NULL,
	[MinCallDate] [datetime] NULL,
	[MaxCallDate] [datetime] NULL,
	[Answered] [int] NULL,
	[Seized] [int] NULL,
	[CallDuration] [decimal](19, 2) NULL
) ON [PRIMARY]
GO
