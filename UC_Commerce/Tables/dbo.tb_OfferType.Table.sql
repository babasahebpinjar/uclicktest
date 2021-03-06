USE [UC_Commerce]
GO
/****** Object:  Table [dbo].[tb_OfferType]    Script Date: 5/2/2020 6:14:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_OfferType](
	[OfferTypeID] [int] NOT NULL,
	[OfferType] [varchar](60) NOT NULL,
	[SourceTypeID] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_OfferType] PRIMARY KEY CLUSTERED 
(
	[OfferTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_OfferType] UNIQUE NONCLUSTERED 
(
	[OfferType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_OfferType] ADD  CONSTRAINT [DF_tb_OfferType_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_OfferType] ADD  CONSTRAINT [DF_tb_OfferType_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_OfferType]  WITH CHECK ADD  CONSTRAINT [FK_tb_OfferType_tb_Sourcetype] FOREIGN KEY([SourceTypeID])
REFERENCES [dbo].[tb_SourceType] ([SourceTypeID])
GO
ALTER TABLE [dbo].[tb_OfferType] CHECK CONSTRAINT [FK_tb_OfferType_tb_Sourcetype]
GO
