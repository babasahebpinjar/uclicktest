USE [UC_Commerce]
GO
/****** Object:  Table [dbo].[tb_RateReAnalysisDetail]    Script Date: 5/2/2020 6:14:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_RateReAnalysisDetail](
	[RateReAnalysisDetailID] [int] IDENTITY(1,1) NOT NULL,
	[NumberPlanAnalysisID] [int] NOT NULL,
	[AnalysisDate] [datetime] NOT NULL,
	[RefDestinationID] [int] NOT NULL,
	[VendorDestinationID] [int] NULL,
	[DDFrom] [varchar](15) NOT NULL,
	[DDTo] [varchar](15) NOT NULL,
	[CountryCode] [varchar](100) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_RateReAnalysisDetail] PRIMARY KEY CLUSTERED 
(
	[RateReAnalysisDetailID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_RateReAnalysisDetail] ADD  CONSTRAINT [DF_tbRateReAnalysisDetail_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_RateReAnalysisDetail] ADD  CONSTRAINT [DF_tbRateReAnalysisDetail_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_RateReAnalysisDetail]  WITH CHECK ADD  CONSTRAINT [FK_tb_RateReAnalysisDetail_tb_NumberPlanAnalysis] FOREIGN KEY([NumberPlanAnalysisID])
REFERENCES [dbo].[tb_NumberPlanAnalysis] ([NumberPlanAnalysisID])
GO
ALTER TABLE [dbo].[tb_RateReAnalysisDetail] CHECK CONSTRAINT [FK_tb_RateReAnalysisDetail_tb_NumberPlanAnalysis]
GO
