USE [UC_Commerce]
GO
/****** Object:  Table [dbo].[tb_RateAnalysisDetail]    Script Date: 5/2/2020 6:14:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_RateAnalysisDetail](
	[RateAnalysisDetailID] [int] IDENTITY(1,1) NOT NULL,
	[OfferID] [int] NOT NULL,
	[AnalysisDate] [datetime] NOT NULL,
	[RefDestinationID] [int] NOT NULL,
	[VendorDestinationID] [int] NULL,
	[DDFrom] [varchar](15) NOT NULL,
	[DDTo] [varchar](15) NOT NULL,
	[CountryCode] [varchar](100) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_RateAnalysisDetail] PRIMARY KEY CLUSTERED 
(
	[RateAnalysisDetailID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_RateAnalysisDetail] ADD  CONSTRAINT [DF_tbRateAnalysisDetail_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_RateAnalysisDetail] ADD  CONSTRAINT [DF_tbRateAnalysisDetail_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_RateAnalysisDetail]  WITH CHECK ADD  CONSTRAINT [FK_tb_RateAnalysisDetail_tb_Offer] FOREIGN KEY([OfferID])
REFERENCES [dbo].[tb_Offer] ([OfferID])
GO
ALTER TABLE [dbo].[tb_RateAnalysisDetail] CHECK CONSTRAINT [FK_tb_RateAnalysisDetail_tb_Offer]
GO
