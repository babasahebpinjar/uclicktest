USE [UC_Commerce]
GO
/****** Object:  Table [dbo].[tb_CustomerPriceUpload]    Script Date: 5/2/2020 6:14:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_CustomerPriceUpload](
	[CustomerPriceUploadID] [int] IDENTITY(1,1) NOT NULL,
	[PriceUploadDate] [datetime] NOT NULL,
	[ExternalFileName] [varchar](500) NOT NULL,
	[CustomerPriceFileName] [varchar](500) NOT NULL,
	[OfferstatusID] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_CustomerOfferUpload] PRIMARY KEY CLUSTERED 
(
	[CustomerPriceUploadID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_CustomerPriceUpload] ADD  CONSTRAINT [DF_tbCustomerPriceUpload_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_CustomerPriceUpload] ADD  CONSTRAINT [DF_tbCustomerPriceUpload_Flag]  DEFAULT ((0)) FOR [Flag]
GO
