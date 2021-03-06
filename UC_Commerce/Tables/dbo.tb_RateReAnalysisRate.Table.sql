USE [UC_Commerce]
GO
/****** Object:  Table [dbo].[tb_RateReAnalysisRate]    Script Date: 5/2/2020 6:14:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_RateReAnalysisRate](
	[RateReAnalysisRateID] [int] IDENTITY(1,1) NOT NULL,
	[NumberPlanAnalysisID] [int] NOT NULL,
	[AnalysisDate] [datetime] NOT NULL,
	[RefDestinationID] [int] NOT NULL,
	[VendorDestinationID] [int] NOT NULL,
	[Rate] [decimal](19, 6) NOT NULL,
	[RateTypeID] [int] NOT NULL,
	[RatingMethodID] [int] NOT NULL,
	[EffectiveDate] [datetime] NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_RateReAnalysisRate] PRIMARY KEY CLUSTERED 
(
	[RateReAnalysisRateID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_RateReAnalysisRate] ADD  CONSTRAINT [DF_tbRateReAnalysisRate_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_RateReAnalysisRate] ADD  CONSTRAINT [DF_tbRateReAnalysisRate_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_RateReAnalysisRate]  WITH CHECK ADD  CONSTRAINT [FK_tb_RateReAnalysisRate_tb_NumberPlanAnalysis] FOREIGN KEY([NumberPlanAnalysisID])
REFERENCES [dbo].[tb_NumberPlanAnalysis] ([NumberPlanAnalysisID])
GO
ALTER TABLE [dbo].[tb_RateReAnalysisRate] CHECK CONSTRAINT [FK_tb_RateReAnalysisRate_tb_NumberPlanAnalysis]
GO
