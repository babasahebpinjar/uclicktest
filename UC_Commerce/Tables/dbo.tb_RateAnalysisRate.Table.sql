USE [UC_Commerce]
GO
/****** Object:  Table [dbo].[tb_RateAnalysisRate]    Script Date: 5/2/2020 6:14:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_RateAnalysisRate](
	[RateAnalysisRateID] [int] IDENTITY(1,1) NOT NULL,
	[OfferID] [int] NOT NULL,
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
 CONSTRAINT [PK_tb_RateAnalysisRate] PRIMARY KEY CLUSTERED 
(
	[RateAnalysisRateID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_RateAnalysisRate] ADD  CONSTRAINT [DF_tbRateAnalysisRate_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_RateAnalysisRate] ADD  CONSTRAINT [DF_tbRateAnalysisRate_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_RateAnalysisRate]  WITH CHECK ADD  CONSTRAINT [FK_tb_RateAnalysisRate_tb_Offer] FOREIGN KEY([OfferID])
REFERENCES [dbo].[tb_Offer] ([OfferID])
GO
ALTER TABLE [dbo].[tb_RateAnalysisRate] CHECK CONSTRAINT [FK_tb_RateAnalysisRate_tb_Offer]
GO
