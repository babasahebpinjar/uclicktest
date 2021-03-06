USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_ProductCatalog]    Script Date: 5/2/2020 6:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_ProductCatalog](
	[ProductCatalogID] [int] IDENTITY(1,1) NOT NULL,
	[ProductCatalog] [varchar](60) NOT NULL,
	[ProductCatalogTypeID] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_ProductCatalog] PRIMARY KEY CLUSTERED 
(
	[ProductCatalogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_ProductCatalog] UNIQUE NONCLUSTERED 
(
	[ProductCatalog] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_ProductCatalog] ADD  CONSTRAINT [DF_tb_ProductCatalog_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_ProductCatalog] ADD  CONSTRAINT [DF_tb_ProductCatalog_ModifiedByID]  DEFAULT ((-1)) FOR [ModifiedByID]
GO
ALTER TABLE [dbo].[tb_ProductCatalog] ADD  CONSTRAINT [DF_tb_ProductCatalog_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_ProductCatalog]  WITH CHECK ADD  CONSTRAINT [FK_tb_ProductCatalog_tb_ProductCatalogType] FOREIGN KEY([ProductCatalogTypeID])
REFERENCES [dbo].[tb_ProductCatalogType] ([ProductCatalogTypeID])
GO
ALTER TABLE [dbo].[tb_ProductCatalog] CHECK CONSTRAINT [FK_tb_ProductCatalog_tb_ProductCatalogType]
GO
