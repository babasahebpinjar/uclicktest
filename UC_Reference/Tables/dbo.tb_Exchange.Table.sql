USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_Exchange]    Script Date: 5/2/2020 6:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_Exchange](
	[ExchangeID] [int] IDENTITY(1,1) NOT NULL,
	[ExchangeRate] [money] NOT NULL,
	[CurrencyID] [int] NOT NULL,
	[BeginDate] [datetime] NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_Exchange] PRIMARY KEY CLUSTERED 
(
	[ExchangeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_Exchange] UNIQUE NONCLUSTERED 
(
	[CurrencyID] ASC,
	[BeginDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_Exchange] ADD  CONSTRAINT [DF_tb_Exchange_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_Exchange] ADD  CONSTRAINT [DF_tb_Exchange_flag]  DEFAULT ((0)) FOR [flag]
GO
ALTER TABLE [dbo].[tb_Exchange]  WITH CHECK ADD  CONSTRAINT [FK_tb_Exchange_tb_Currency] FOREIGN KEY([CurrencyID])
REFERENCES [dbo].[tb_Currency] ([CurrencyID])
GO
ALTER TABLE [dbo].[tb_Exchange] CHECK CONSTRAINT [FK_tb_Exchange_tb_Currency]
GO
