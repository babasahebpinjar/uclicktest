USE [UC_Admin]
GO
/****** Object:  Table [dbo].[tb_ModuleAccess]    Script Date: 5/2/2020 5:58:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_ModuleAccess](
	[ModuleAccessID] [int] IDENTITY(1,1) NOT NULL,
	[ModuleName] [varchar](100) NOT NULL,
	[AccessScope] [int] NOT NULL,
 CONSTRAINT [PK_tb_ModuleAccess] PRIMARY KEY CLUSTERED 
(
	[ModuleAccessID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [uc_ModuleName_AccessScope] UNIQUE NONCLUSTERED 
(
	[ModuleName] ASC,
	[AccessScope] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
