USE [UC_Commerce]
GO
/****** Object:  Table [dbo].[tb_NumberPlanAnalysis]    Script Date: 5/2/2020 6:14:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_NumberPlanAnalysis](
	[NumberPlanAnalysisID] [int] IDENTITY(1,1) NOT NULL,
	[AnalysisRegisterDate] [datetime] NULL,
	[AnalysisStartDate] [date] NULL,
	[SourceID] [int] NOT NULL,
	[AnalysisType] [varchar](50) NOT NULL,
	[AnalysisStatusID] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_NumberPlanAnalysis] PRIMARY KEY CLUSTERED 
(
	[NumberPlanAnalysisID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_NumberPlanAnalysis] UNIQUE NONCLUSTERED 
(
	[AnalysisRegisterDate] ASC,
	[SourceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_NumberPlanAnalysis] ADD  CONSTRAINT [DF_tb_NumberPlanAnalysis_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_NumberPlanAnalysis] ADD  CONSTRAINT [DF_tb_NumberPlanAnalysis_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_NumberPlanAnalysis]  WITH CHECK ADD  CONSTRAINT [FK_tb_NumberPlanAnalysis_tb_NumberPlanAnalysisStatus] FOREIGN KEY([AnalysisStatusID])
REFERENCES [dbo].[tb_NumberPlanAnalysisStatus] ([NumberPlanAnalysisStatusID])
GO
ALTER TABLE [dbo].[tb_NumberPlanAnalysis] CHECK CONSTRAINT [FK_tb_NumberPlanAnalysis_tb_NumberPlanAnalysisStatus]
GO
ALTER TABLE [dbo].[tb_NumberPlanAnalysis]  WITH CHECK ADD  CONSTRAINT [FK_tb_NumberPlanAnalysis_tb_Source] FOREIGN KEY([SourceID])
REFERENCES [dbo].[tb_Source] ([SourceID])
GO
ALTER TABLE [dbo].[tb_NumberPlanAnalysis] CHECK CONSTRAINT [FK_tb_NumberPlanAnalysis_tb_Source]
GO
