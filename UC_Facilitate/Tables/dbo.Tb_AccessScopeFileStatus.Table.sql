USE [UC_Facilitate]
GO
/****** Object:  Table [dbo].[Tb_AccessScopeFileStatus]    Script Date: 5/2/2020 6:47:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tb_AccessScopeFileStatus](
	[FileStatus] [varchar](200) NOT NULL,
	[AccessScopeID] [int] NOT NULL,
 CONSTRAINT [uc_AccessScopeFileStatus] UNIQUE NONCLUSTERED 
(
	[FileStatus] ASC,
	[AccessScopeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Tb_AccessScopeFileStatus]  WITH CHECK ADD  CONSTRAINT [FK_Tb_AccessScopeFileStatus_tb_AccessScope] FOREIGN KEY([AccessScopeID])
REFERENCES [dbo].[tb_AccessScope] ([AccessScopeID])
GO
ALTER TABLE [dbo].[Tb_AccessScopeFileStatus] CHECK CONSTRAINT [FK_Tb_AccessScopeFileStatus_tb_AccessScope]
GO
