USE [UC_Commerce]
GO
/****** Object:  Table [dbo].[tb_CustomerPriceUploadDetails]    Script Date: 5/2/2020 6:14:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_CustomerPriceUploadDetails](
	[CustomerPriceUploadID] [int] NOT NULL,
	[DestinationID] [int] NOT NULL,
	[EffectiveDate] [datetime] NOT NULL,
	[RatingMethodID] [int] NOT NULL,
	[Rate1] [decimal](19, 6) NOT NULL,
	[Rate2] [decimal](19, 6) NULL,
	[Rate3] [decimal](19, 6) NULL,
	[Rate4] [decimal](19, 6) NULL,
	[Rate5] [decimal](19, 6) NULL,
	[Rate6] [decimal](19, 6) NULL,
	[Rate7] [decimal](19, 6) NULL,
	[Rate8] [decimal](19, 6) NULL,
	[Rate9] [decimal](19, 6) NULL,
	[Rate10] [decimal](19, 6) NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [UC_tb_CustomerPriceUploadDetails] UNIQUE NONCLUSTERED 
(
	[CustomerPriceUploadID] ASC,
	[DestinationID] ASC,
	[EffectiveDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_CustomerPriceUploadDetails]  WITH CHECK ADD  CONSTRAINT [FK_tb_CustomerPriceUploadDetails_tb_CustomerPriceUpload] FOREIGN KEY([CustomerPriceUploadID])
REFERENCES [dbo].[tb_CustomerPriceUpload] ([CustomerPriceUploadID])
GO
ALTER TABLE [dbo].[tb_CustomerPriceUploadDetails] CHECK CONSTRAINT [FK_tb_CustomerPriceUploadDetails_tb_CustomerPriceUpload]
GO
