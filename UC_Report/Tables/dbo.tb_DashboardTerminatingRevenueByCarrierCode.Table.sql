USE [UC_Report]
GO
/****** Object:  Table [dbo].[tb_DashboardTerminatingRevenueByCarrierCode]    Script Date: 5/2/2020 6:38:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_DashboardTerminatingRevenueByCarrierCode](
	[CarrierCode] [varchar](100) NULL,
	[Answered] [int] NULL,
	[Seized] [int] NULL,
	[ASR] [int] NULL,
	[OriginalMinutes] [decimal](19, 2) NULL,
	[ChargeMinutes] [decimal](19, 2) NULL,
	[Revenue] [decimal](19, 2) NULL,
	[RPM] [decimal](19, 6) NULL
) ON [PRIMARY]
GO
