USE [UC_Commerce]
GO
/****** Object:  Table [dbo].[tb_Offer]    Script Date: 5/2/2020 6:14:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_Offer](
	[OfferID] [int] IDENTITY(1,1) NOT NULL,
	[ExternalOfferFileName] [varchar](500) NULL,
	[OfferFileName] [varchar](500) NULL,
	[OfferDate] [datetime] NULL,
	[OfferTypeID] [int] NOT NULL,
	[SourceID] [int] NOT NULL,
	[OfferContent] [varchar](50) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_offer] PRIMARY KEY CLUSTERED 
(
	[OfferID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_offer] UNIQUE NONCLUSTERED 
(
	[OfferDate] ASC,
	[SourceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_Offer] ADD  CONSTRAINT [DF_tb_offer_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_Offer] ADD  CONSTRAINT [DF_tb_offer_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_Offer]  WITH CHECK ADD  CONSTRAINT [FK_tb_offer_tb_Offertype] FOREIGN KEY([OfferTypeID])
REFERENCES [dbo].[tb_OfferType] ([OfferTypeID])
GO
ALTER TABLE [dbo].[tb_Offer] CHECK CONSTRAINT [FK_tb_offer_tb_Offertype]
GO
ALTER TABLE [dbo].[tb_Offer]  WITH CHECK ADD  CONSTRAINT [FK_tb_offer_tb_Source] FOREIGN KEY([SourceID])
REFERENCES [dbo].[tb_Source] ([SourceID])
GO
ALTER TABLE [dbo].[tb_Offer] CHECK CONSTRAINT [FK_tb_offer_tb_Source]
GO
