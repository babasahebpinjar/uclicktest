USE [UC_Bridge]
GO
/****** Object:  Table [dbo].[tb_OfferStatus]    Script Date: 5/2/2020 6:44:26 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_OfferStatus](
	[OfferStatusID] [int] IDENTITY(1,1) NOT NULL,
	[OfferStatus] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_tb_OfferStatus] PRIMARY KEY CLUSTERED 
(
	[OfferStatusID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
