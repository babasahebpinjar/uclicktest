USE [UC_Report]
GO
/****** Object:  Table [dbo].[tb_MasterlogExtractStatus]    Script Date: 5/2/2020 6:38:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_MasterlogExtractStatus](
	[MasterlogExtractStatusID] [int] NOT NULL,
	[MasterlogExtractStatus] [varchar](100) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_MasterlogExtractStatus] PRIMARY KEY CLUSTERED 
(
	[MasterlogExtractStatusID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_MasterlogExtractStatus] UNIQUE NONCLUSTERED 
(
	[MasterlogExtractStatus] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
