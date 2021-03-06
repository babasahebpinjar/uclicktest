USE [UC_Report]
GO
/****** Object:  Table [dbo].[tb_CDRExtractStatusWorkflow]    Script Date: 5/2/2020 6:38:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_CDRExtractStatusWorkflow](
	[CDRExtractStatusWorkflowID] [int] NOT NULL,
	[FromCDRExtractStatusID] [int] NOT NULL,
	[ToCDRExtractStatusID] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_CDRExtractStatusWorkflow] PRIMARY KEY CLUSTERED 
(
	[CDRExtractStatusWorkflowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_CDRExtractStatusWorkflow] UNIQUE NONCLUSTERED 
(
	[FromCDRExtractStatusID] ASC,
	[ToCDRExtractStatusID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
