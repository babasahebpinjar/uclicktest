USE [UC_Report]
GO
/****** Object:  Table [dbo].[tb_PrepaidCurrentBalance]    Script Date: 5/2/2020 6:38:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_PrepaidCurrentBalance](
	[AccountID] [int] NOT NULL,
	[CallDate] [date] NOT NULL,
	[Amount] [decimal](19, 2) NULL,
	[ModifiedByID] [int] NULL,
	[ModifiedDate] [datetime] NULL,
 CONSTRAINT [UC_tb_PrepaidCurrentBalance] UNIQUE NONCLUSTERED 
(
	[AccountID] ASC,
	[CallDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_PrepaidCurrentBalance] ADD  CONSTRAINT [DF_tb_PrepaidCurrentBalance_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
