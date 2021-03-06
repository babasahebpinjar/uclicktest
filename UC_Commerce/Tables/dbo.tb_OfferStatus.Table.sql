USE [UC_Commerce]
GO
/****** Object:  Table [dbo].[tb_OfferStatus]    Script Date: 5/2/2020 6:14:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_OfferStatus](
	[OfferStatusID] [int] NOT NULL,
	[OfferStatus] [varchar](60) NOT NULL,
	[OfferTypeID] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_OfferStatus] PRIMARY KEY CLUSTERED 
(
	[OfferStatusID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_OfferStatus] UNIQUE NONCLUSTERED 
(
	[OfferTypeID] ASC,
	[OfferStatus] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_OfferStatus] ADD  CONSTRAINT [DF_tb_OfferStatus_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_OfferStatus] ADD  CONSTRAINT [DF_tb_OfferStatus_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_OfferStatus]  WITH CHECK ADD  CONSTRAINT [FK_tb_OfferStatus_tb_Offertype] FOREIGN KEY([OfferTypeID])
REFERENCES [dbo].[tb_OfferType] ([OfferTypeID])
GO
ALTER TABLE [dbo].[tb_OfferStatus] CHECK CONSTRAINT [FK_tb_OfferStatus_tb_Offertype]
GO
