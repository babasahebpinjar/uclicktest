USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_Currency]    Script Date: 5/2/2020 6:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_Currency](
	[CurrencyID] [int] IDENTITY(1,1) NOT NULL,
	[Currency] [varchar](30) NOT NULL,
	[CurrencyAbbrv] [varchar](10) NOT NULL,
	[CurrencySymbol] [varchar](8) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_Currency] PRIMARY KEY CLUSTERED 
(
	[CurrencyID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_Currency] UNIQUE NONCLUSTERED 
(
	[Currency] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_Currency] ADD  CONSTRAINT [DF_tb_Currency_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_Currency] ADD  CONSTRAINT [DF_tb_Currency_Flag]  DEFAULT ((0)) FOR [Flag]
GO
