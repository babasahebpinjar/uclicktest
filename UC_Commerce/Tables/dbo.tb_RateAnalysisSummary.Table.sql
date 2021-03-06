USE [UC_Commerce]
GO
/****** Object:  Table [dbo].[tb_RateAnalysisSummary]    Script Date: 5/2/2020 6:14:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_RateAnalysisSummary](
	[RateAnalysisSummaryID] [int] IDENTITY(1,1) NOT NULL,
	[RateAnalysisID] [int] NOT NULL,
	[RateTypeID] [int] NOT NULL,
	[AnalyzedRate] [decimal](19, 6) NOT NULL,
	[RateMax] [decimal](19, 6) NOT NULL,
	[RateMin] [decimal](19, 6) NOT NULL,
	[RateROC] [decimal](19, 6) NULL,
	[PrevRate] [decimal](19, 6) NULL,
	[PrevBeginDate] [datetime] NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_RateAnalysisSummary] PRIMARY KEY CLUSTERED 
(
	[RateAnalysisSummaryID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_RateAnalysisSummary] ADD  CONSTRAINT [DF_tbRateAnalysisSummary_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_RateAnalysisSummary] ADD  CONSTRAINT [DF_tbRateAnalysisSummary_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_RateAnalysisSummary]  WITH CHECK ADD  CONSTRAINT [FK_tb_RateAnalysisSummary_tb_RateAnalysis] FOREIGN KEY([RateAnalysisID])
REFERENCES [dbo].[tb_RateAnalysis] ([RateAnalysisID])
GO
ALTER TABLE [dbo].[tb_RateAnalysisSummary] CHECK CONSTRAINT [FK_tb_RateAnalysisSummary_tb_RateAnalysis]
GO
