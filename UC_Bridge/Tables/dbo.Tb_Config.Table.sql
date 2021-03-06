USE [UC_Bridge]
GO
/****** Object:  Table [dbo].[Tb_Config]    Script Date: 5/2/2020 6:44:26 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tb_Config](
	[Configname] [varchar](200) NULL,
	[ConfigValue] [varchar](1000) NULL,
 CONSTRAINT [uc_ConfigName] UNIQUE NONCLUSTERED 
(
	[Configname] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
