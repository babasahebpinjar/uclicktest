USE [UC_Commerce]
GO
/****** Object:  Table [dbo].[tb_UIChartTopNOffersProcessed]    Script Date: 5/2/2020 6:14:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_UIChartTopNOffersProcessed](
	[OfferID] [int] NULL,
	[ExternalOfferFileName] [varchar](500) NULL,
	[OfferFileName] [varchar](500) NULL,
	[OfferDate] [datetime] NULL,
	[OfferContent] [varchar](50) NULL,
	[OfferStatus] [varchar](100) NULL
) ON [PRIMARY]
GO
