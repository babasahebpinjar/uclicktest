USE [UC_Report]
GO
/****** Object:  Table [dbo].[tb_DashboardHourlyQOS]    Script Date: 5/2/2020 6:38:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_DashboardHourlyQOS](
	[CallHour] [varchar](6) NULL,
	[ASR] [int] NULL,
	[TotalMinutes] [decimal](19, 2) NULL,
	[MHT] [decimal](19, 2) NULL,
	[ALOC] [decimal](19, 2) NULL
) ON [PRIMARY]
GO
