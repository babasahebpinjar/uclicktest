USE [UC_Commerce]
GO
/****** Object:  Table [dbo].[tb_CustomerPriceUploadSource]    Script Date: 5/2/2020 6:14:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_CustomerPriceUploadSource](
	[CustomerPriceUploadID] [int] NOT NULL,
	[SourceID] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [UC_tb_CustomerPriceUploadSource] UNIQUE NONCLUSTERED 
(
	[CustomerPriceUploadID] ASC,
	[SourceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_CustomerPriceUploadSource]  WITH CHECK ADD  CONSTRAINT [FK_tb_CustomerPriceUploadSource_tb_CustomerPriceUpload] FOREIGN KEY([CustomerPriceUploadID])
REFERENCES [dbo].[tb_CustomerPriceUpload] ([CustomerPriceUploadID])
GO
ALTER TABLE [dbo].[tb_CustomerPriceUploadSource] CHECK CONSTRAINT [FK_tb_CustomerPriceUploadSource_tb_CustomerPriceUpload]
GO
ALTER TABLE [dbo].[tb_CustomerPriceUploadSource]  WITH CHECK ADD  CONSTRAINT [FK_tb_CustomerPriceUploadSource_tb_Source] FOREIGN KEY([SourceID])
REFERENCES [dbo].[tb_Source] ([SourceID])
GO
ALTER TABLE [dbo].[tb_CustomerPriceUploadSource] CHECK CONSTRAINT [FK_tb_CustomerPriceUploadSource_tb_Source]
GO
