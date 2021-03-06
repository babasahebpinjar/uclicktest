USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_Account]    Script Date: 5/2/2020 6:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_Account](
	[AccountID] [int] IDENTITY(1,1) NOT NULL,
	[Account] [varchar](60) NOT NULL,
	[AccountAbbrv] [varchar](30) NOT NULL,
	[AccountNumber] [varchar](30) NOT NULL,
	[CreditLimit] [money] NULL,
	[Deposit] [money] NULL,
	[Address1] [varchar](50) NULL,
	[Address2] [varchar](50) NULL,
	[City] [varchar](50) NULL,
	[State] [varchar](50) NULL,
	[Zip] [varchar](50) NULL,
	[Phone] [varchar](50) NULL,
	[Fax] [varchar](50) NULL,
	[Comment] [varchar](8000) NULL,
	[AccountTypeID] [int] NOT NULL,
	[CompanyID] [int] NOT NULL,
	[BuyerID] [int] NULL,
	[SellerID] [int] NULL,
	[ContactPersonID] [int] NULL,
	[CountryID] [int] NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_Account] PRIMARY KEY CLUSTERED 
(
	[AccountID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_Account] UNIQUE NONCLUSTERED 
(
	[Account] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_Account_AccountAbbrv] UNIQUE NONCLUSTERED 
(
	[AccountAbbrv] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_Account_AccountNumber] UNIQUE NONCLUSTERED 
(
	[AccountNumber] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_Account] ADD  CONSTRAINT [DF_tb_Account_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_Account] ADD  CONSTRAINT [DF_tb_Account_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_Account]  WITH CHECK ADD  CONSTRAINT [FK_tb_Account_tb_AccountType] FOREIGN KEY([AccountTypeID])
REFERENCES [dbo].[tb_AccountType] ([AccountTypeID])
GO
ALTER TABLE [dbo].[tb_Account] CHECK CONSTRAINT [FK_tb_Account_tb_AccountType]
GO
ALTER TABLE [dbo].[tb_Account]  WITH CHECK ADD  CONSTRAINT [FK_tb_Account_tb_Company] FOREIGN KEY([CompanyID])
REFERENCES [dbo].[tb_Company] ([CompanyID])
GO
ALTER TABLE [dbo].[tb_Account] CHECK CONSTRAINT [FK_tb_Account_tb_Company]
GO
ALTER TABLE [dbo].[tb_Account]  WITH CHECK ADD  CONSTRAINT [FK_tb_Account_tb_Country] FOREIGN KEY([CountryID])
REFERENCES [dbo].[tb_Country] ([CountryID])
GO
ALTER TABLE [dbo].[tb_Account] CHECK CONSTRAINT [FK_tb_Account_tb_Country]
GO
