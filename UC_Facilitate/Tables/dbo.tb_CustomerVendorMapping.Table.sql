USE [UC_Facilitate]
GO
/****** Object:  Table [dbo].[tb_CustomerVendorMapping]    Script Date: 5/2/2020 6:47:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_CustomerVendorMapping](
	[Account] [varchar](100) NULL,
	[CustomerCode] [varchar](100) NULL,
	[VendorCode] [varchar](100) NULL,
	[Assignment] [varchar](100) NULL,
	[Country] [varchar](100) NULL,
	[Currency] [varchar](100) NULL
) ON [PRIMARY]
GO
