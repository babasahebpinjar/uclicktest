USE [UC_Commerce]
GO
/****** Object:  Table [dbo].[tb_UploadRate]    Script Date: 5/2/2020 6:14:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_UploadRate](
	[UploadRateID] [int] IDENTITY(1,1) NOT NULL,
	[OfferID] [int] NOT NULL,
	[UploadDestinationID] [int] NOT NULL,
	[Rate] [decimal](19, 6) NOT NULL,
	[RateTypeID] [int] NOT NULL,
	[EffectiveDate] [datetime] NOT NULL,
	[AmountChange] [decimal](19, 6) NULL,
	[PrevBeginDate] [datetime] NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_UploadRate] PRIMARY KEY NONCLUSTERED 
(
	[UploadRateID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_UploadRate] ADD  CONSTRAINT [DF_tb_UploadRate_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_UploadRate] ADD  CONSTRAINT [DF_tb_UploadRate_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_UploadRate]  WITH CHECK ADD  CONSTRAINT [FK_tb_UploadRate_tb_UploadDestination] FOREIGN KEY([UploadDestinationID])
REFERENCES [dbo].[tb_UploadDestination] ([UploadDestinationID])
GO
ALTER TABLE [dbo].[tb_UploadRate] CHECK CONSTRAINT [FK_tb_UploadRate_tb_UploadDestination]
GO
