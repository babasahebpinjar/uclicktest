USE [UC_Commerce]
GO
/****** Object:  Table [dbo].[tb_RateAnalysis]    Script Date: 5/2/2020 6:14:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_RateAnalysis](
	[RateAnalysisID] [int] IDENTITY(1,1) NOT NULL,
	[OfferID] [int] NOT NULL,
	[AnalysisDate] [datetime] NOT NULL,
	[RefDestinationID] [int] NOT NULL,
	[RatingMethodID] [int] NULL,
	[DiscrepancyFlag] [int] NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_RateAnalysis] PRIMARY KEY CLUSTERED 
(
	[RateAnalysisID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_RateAnalysis] ADD  CONSTRAINT [DF_tbRateAnalysis_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_RateAnalysis] ADD  CONSTRAINT [DF_tbRateAnalysis_Flag]  DEFAULT ((0)) FOR [Flag]
GO
