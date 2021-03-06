USE [UC_Operations]
GO
/****** Object:  Table [dbo].[tb_KPIRefreshStatus]    Script Date: 5/2/2020 6:24:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_KPIRefreshStatus](
	[KPIRefreshStatusID] [int] NOT NULL,
	[KPIRefreshStatus] [varchar](100) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NULL,
 CONSTRAINT [PK_tb_KPIRefreshStatus] PRIMARY KEY CLUSTERED 
(
	[KPIRefreshStatusID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [uc_KPIRefreshStatus] UNIQUE NONCLUSTERED 
(
	[KPIRefreshStatus] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
