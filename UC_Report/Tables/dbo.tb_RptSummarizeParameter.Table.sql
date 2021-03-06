USE [UC_Report]
GO
/****** Object:  Table [dbo].[tb_RptSummarizeParameter]    Script Date: 5/2/2020 6:38:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_RptSummarizeParameter](
	[RptSummarizeParameterID] [int] NOT NULL,
	[RptSummarizeParameterName] [varchar](60) NOT NULL,
	[RptSummarizeParameterValue] [varchar](60) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
	[RptSummarizeParameterFormat] [varchar](100) NULL,
 CONSTRAINT [PK_tb_RptSummarizeParameter] PRIMARY KEY CLUSTERED 
(
	[RptSummarizeParameterID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_RptSummarizeParameter] UNIQUE NONCLUSTERED 
(
	[RptSummarizeParameterName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
