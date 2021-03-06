USE [UC_Report]
GO
/****** Object:  Table [dbo].[TB_Masterlog_AccessScopeFileStatus]    Script Date: 5/2/2020 6:38:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_Masterlog_AccessScopeFileStatus](
	[FileStatus] [varchar](200) NOT NULL,
	[AccessScopeID] [int] NOT NULL,
 CONSTRAINT [uc_AccessScopeFileStatus] UNIQUE NONCLUSTERED 
(
	[FileStatus] ASC,
	[AccessScopeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
