USE [UC_Admin]
GO
/****** Object:  Table [dbo].[tb_AccessRoles]    Script Date: 5/2/2020 5:58:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_AccessRoles](
	[AccessRolesID] [int] IDENTITY(1,1) NOT NULL,
	[AccessRolesName] [varchar](50) NOT NULL,
	[AccessScopeID] [int] NOT NULL,
 CONSTRAINT [PK_tb_AccessRoles] PRIMARY KEY CLUSTERED 
(
	[AccessRolesID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [uc_AccessRolesName] UNIQUE NONCLUSTERED 
(
	[AccessRolesName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_AccessRoles]  WITH CHECK ADD  CONSTRAINT [FK_tb_Accessroles_tb_AccessScope] FOREIGN KEY([AccessScopeID])
REFERENCES [dbo].[tb_AccessScope] ([AccessScopeID])
GO
ALTER TABLE [dbo].[tb_AccessRoles] CHECK CONSTRAINT [FK_tb_Accessroles_tb_AccessScope]
GO
