USE [UC_Facilitate]
GO
/****** Object:  Table [dbo].[Tb_Config]    Script Date: 5/2/2020 6:47:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tb_Config](
	[Configname] [varchar](200) NOT NULL,
	[AccessScopeID] [int] NOT NULL,
	[ConfigDataTypeID] [int] NOT NULL,
	[ConfigValue] [varchar](1000) NOT NULL,
 CONSTRAINT [uc_ConfigName] UNIQUE NONCLUSTERED 
(
	[Configname] ASC,
	[AccessScopeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Tb_Config]  WITH CHECK ADD  CONSTRAINT [FK_tb_Config_tb_AccessScope] FOREIGN KEY([AccessScopeID])
REFERENCES [dbo].[tb_AccessScope] ([AccessScopeID])
GO
ALTER TABLE [dbo].[Tb_Config] CHECK CONSTRAINT [FK_tb_Config_tb_AccessScope]
GO
ALTER TABLE [dbo].[Tb_Config]  WITH CHECK ADD  CONSTRAINT [FK_tb_Config_tb_ConfigDatatype] FOREIGN KEY([ConfigDataTypeID])
REFERENCES [dbo].[Tb_ConfigDataType] ([ConfigDataTypeID])
GO
ALTER TABLE [dbo].[Tb_Config] CHECK CONSTRAINT [FK_tb_Config_tb_ConfigDatatype]
GO
