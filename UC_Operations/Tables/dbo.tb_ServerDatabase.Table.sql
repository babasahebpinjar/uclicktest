USE [UC_Operations]
GO
/****** Object:  Table [dbo].[tb_ServerDatabase]    Script Date: 5/2/2020 6:24:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_ServerDatabase](
	[ServerDatabaseID] [int] IDENTITY(1,1) NOT NULL,
	[ServerID] [int] NOT NULL,
	[DatabaseID] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
 CONSTRAINT [PK_tb_ServerDatabase] PRIMARY KEY CLUSTERED 
(
	[ServerDatabaseID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_ServerDatabase_1] UNIQUE NONCLUSTERED 
(
	[ServerID] ASC,
	[DatabaseID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_ServerDatabase_2] UNIQUE NONCLUSTERED 
(
	[DatabaseID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_ServerDatabase]  WITH CHECK ADD  CONSTRAINT [FK_tb_ServerDatabase_tb_Database] FOREIGN KEY([DatabaseID])
REFERENCES [dbo].[tb_Database] ([DatabaseID])
GO
ALTER TABLE [dbo].[tb_ServerDatabase] CHECK CONSTRAINT [FK_tb_ServerDatabase_tb_Database]
GO
ALTER TABLE [dbo].[tb_ServerDatabase]  WITH CHECK ADD  CONSTRAINT [FK_tb_ServerDatabase_tb_Server] FOREIGN KEY([ServerID])
REFERENCES [dbo].[tb_Server] ([ServerID])
GO
ALTER TABLE [dbo].[tb_ServerDatabase] CHECK CONSTRAINT [FK_tb_ServerDatabase_tb_Server]
GO
