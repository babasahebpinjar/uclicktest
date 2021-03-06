USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_AccountReceivable]    Script Date: 5/2/2020 6:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_AccountReceivable](
	[AccountReceivableID] [int] IDENTITY(1,1) NOT NULL,
	[AccountID] [int] NOT NULL,
	[AccountReceivableTypeID] [int] NOT NULL,
	[PostingDate] [date] NOT NULL,
	[Description] [varchar](500) NOT NULL,
	[Amount] [decimal](19, 2) NOT NULL,
	[CurrencyID] [int] NOT NULL,
	[ExchangeRate] [decimal](19, 4) NOT NULL,
	[StatementNumber] [varchar](100) NOT NULL,
	[PhysicalInvoice] [varchar](500) NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
 CONSTRAINT [PK_tb_AccountReceivable] PRIMARY KEY CLUSTERED 
(
	[AccountReceivableID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_AccountReceivable] ADD  CONSTRAINT [DF_tb_AccountReceivable_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_AccountReceivable] ADD  CONSTRAINT [DF_tb_AccountReceivable_ModifiedByID]  DEFAULT ((-1)) FOR [ModifiedByID]
GO
ALTER TABLE [dbo].[tb_AccountReceivable]  WITH CHECK ADD  CONSTRAINT [FK_tb_AccountReceivable_tb_Account] FOREIGN KEY([AccountID])
REFERENCES [dbo].[tb_Account] ([AccountID])
GO
ALTER TABLE [dbo].[tb_AccountReceivable] CHECK CONSTRAINT [FK_tb_AccountReceivable_tb_Account]
GO
ALTER TABLE [dbo].[tb_AccountReceivable]  WITH CHECK ADD  CONSTRAINT [FK_tb_AccountReceivable_tb_AccountReceivableType] FOREIGN KEY([AccountReceivableTypeID])
REFERENCES [dbo].[tb_AccountReceivableType] ([AccountReceivableTypeID])
GO
ALTER TABLE [dbo].[tb_AccountReceivable] CHECK CONSTRAINT [FK_tb_AccountReceivable_tb_AccountReceivableType]
GO
ALTER TABLE [dbo].[tb_AccountReceivable]  WITH CHECK ADD  CONSTRAINT [FK_tb_AccountReceivable_tb_Currency] FOREIGN KEY([CurrencyID])
REFERENCES [dbo].[tb_Currency] ([CurrencyID])
GO
ALTER TABLE [dbo].[tb_AccountReceivable] CHECK CONSTRAINT [FK_tb_AccountReceivable_tb_Currency]
GO
