USE [UC_Commerce]
GO
/****** Object:  Table [dbo].[tb_RateReAnalysisSummary]    Script Date: 5/2/2020 6:14:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_RateReAnalysisSummary](
	[RateReAnalysisSummaryID] [int] IDENTITY(1,1) NOT NULL,
	[RateReAnalysisID] [int] NOT NULL,
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
 CONSTRAINT [PK_tb_RateReAnalysisSummary] PRIMARY KEY CLUSTERED 
(
	[RateReAnalysisSummaryID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_RateReAnalysisSummary] ADD  CONSTRAINT [DF_tbRateReAnalysisSummary_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_RateReAnalysisSummary] ADD  CONSTRAINT [DF_tbRateReAnalysisSummary_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_RateReAnalysisSummary]  WITH CHECK ADD  CONSTRAINT [FK_tb_RateReAnalysisSummary_tb_RateReAnalysis] FOREIGN KEY([RateReAnalysisID])
REFERENCES [dbo].[tb_RateReAnalysis] ([RateReAnalysisID])
GO
ALTER TABLE [dbo].[tb_RateReAnalysisSummary] CHECK CONSTRAINT [FK_tb_RateReAnalysisSummary_tb_RateReAnalysis]
GO
