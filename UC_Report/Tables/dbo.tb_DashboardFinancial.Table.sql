USE [UC_Report]
GO
/****** Object:  Table [dbo].[tb_DashboardFinancial]    Script Date: 5/2/2020 6:38:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_DashboardFinancial](
	[TrafficDirection] [varchar](50) NULL,
	[Seized] [int] NULL,
	[Answered] [int] NULL,
	[UnRoundedCallDuration] [decimal](19, 2) NULL,
	[ChargeDuration] [decimal](19, 2) NULL,
	[Amount] [decimal](19, 2) NULL,
	[Rate] [decimal](19, 4) NULL
) ON [PRIMARY]
GO
