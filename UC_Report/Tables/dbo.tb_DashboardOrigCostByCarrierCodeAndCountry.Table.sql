USE [UC_Report]
GO
/****** Object:  Table [dbo].[tb_DashboardOrigCostByCarrierCodeAndCountry]    Script Date: 5/2/2020 6:38:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_DashboardOrigCostByCarrierCodeAndCountry](
	[CarrierCode] [varchar](100) NULL,
	[Country] [varchar](100) NULL,
	[Answered] [int] NULL,
	[Seized] [int] NULL,
	[ASR] [int] NULL,
	[OriginalMinutes] [decimal](19, 2) NULL,
	[ChargeMinutes] [decimal](19, 2) NULL,
	[Cost] [decimal](19, 2) NULL,
	[CPM] [decimal](19, 6) NULL
) ON [PRIMARY]
GO
