USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_AccountMode]    Script Date: 5/2/2020 6:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_AccountMode](
	[AccountModeID] [int] IDENTITY(1,1) NOT NULL,
	[AccountID] [int] NOT NULL,
	[AccountModeTypeID] [int] NOT NULL,
	[Period] [int] NOT NULL,
	[Comment] [varchar](1000) NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
 CONSTRAINT [PK_tb_AccountMode] PRIMARY KEY CLUSTERED 
(
	[AccountModeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_AccountMode] UNIQUE NONCLUSTERED 
(
	[AccountID] ASC,
	[Period] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_AccountMode] ADD  CONSTRAINT [DF_tb_AccountMode_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_AccountMode] ADD  CONSTRAINT [DF_tb_AccountMode_ModifiedByID]  DEFAULT ((-1)) FOR [ModifiedByID]
GO
ALTER TABLE [dbo].[tb_AccountMode]  WITH CHECK ADD  CONSTRAINT [FK_tb_AccountMode_tb_Account] FOREIGN KEY([AccountID])
REFERENCES [dbo].[tb_Account] ([AccountID])
GO
ALTER TABLE [dbo].[tb_AccountMode] CHECK CONSTRAINT [FK_tb_AccountMode_tb_Account]
GO
ALTER TABLE [dbo].[tb_AccountMode]  WITH CHECK ADD  CONSTRAINT [FK_tb_AccountMode_tb_AccountModeType] FOREIGN KEY([AccountModeTypeID])
REFERENCES [dbo].[tb_AccountModeType] ([AccountModeTypeID])
GO
ALTER TABLE [dbo].[tb_AccountMode] CHECK CONSTRAINT [FK_tb_AccountMode_tb_AccountModeType]
GO
