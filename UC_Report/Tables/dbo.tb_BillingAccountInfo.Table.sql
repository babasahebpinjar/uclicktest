USE [UC_Report]
GO
/****** Object:  Table [dbo].[tb_BillingAccountInfo]    Script Date: 5/2/2020 6:38:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_BillingAccountInfo](
	[AccountID] [int] NOT NULL,
	[CompanyName] [varchar](200) NULL,
	[CustomerCode] [varchar](50) NULL,
	[VendorCode] [varchar](50) NULL,
	[Assignment] [varchar](50) NULL,
	[Country] [varchar](100) NULL,
	[Contactname] [varchar](500) NULL,
	[Address1] [varchar](500) NULL,
	[Address2] [varchar](500) NULL,
	[Address3] [varchar](500) NULL,
	[Address4] [varchar](500) NULL,
	[EmailAddress] [varchar](500) NULL,
	[RevenueStatement] [varchar](100) NULL,
	[CostStatement] [varchar](100) NULL,
	[BankAccount] [varchar](100) NULL
) ON [PRIMARY]
GO
