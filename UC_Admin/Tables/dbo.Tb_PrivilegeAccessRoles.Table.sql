USE [UC_Admin]
GO
/****** Object:  Table [dbo].[Tb_PrivilegeAccessRoles]    Script Date: 5/2/2020 5:58:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tb_PrivilegeAccessRoles](
	[PrivilegeAccessRolesID] [int] IDENTITY(1,1) NOT NULL,
	[UserPrivilegeID] [int] NOT NULL,
	[AccessRolesID] [int] NOT NULL,
 CONSTRAINT [PK_Tb_PrivilegeAccessRoles] PRIMARY KEY CLUSTERED 
(
	[PrivilegeAccessRolesID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [uc_UserPrivilegeID_AccessRolesID] UNIQUE NONCLUSTERED 
(
	[UserPrivilegeID] ASC,
	[AccessRolesID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Tb_PrivilegeAccessRoles]  WITH CHECK ADD  CONSTRAINT [FK_Tb_PrivilegeAccessRoles_tb_AccessRoles] FOREIGN KEY([AccessRolesID])
REFERENCES [dbo].[tb_AccessRoles] ([AccessRolesID])
GO
ALTER TABLE [dbo].[Tb_PrivilegeAccessRoles] CHECK CONSTRAINT [FK_Tb_PrivilegeAccessRoles_tb_AccessRoles]
GO
ALTER TABLE [dbo].[Tb_PrivilegeAccessRoles]  WITH CHECK ADD  CONSTRAINT [FK_Tb_PrivilegeAccessRoles_Tb_UserPrivilege] FOREIGN KEY([UserPrivilegeID])
REFERENCES [dbo].[tb_UserPrivilege] ([UserPrivilegeID])
GO
ALTER TABLE [dbo].[Tb_PrivilegeAccessRoles] CHECK CONSTRAINT [FK_Tb_PrivilegeAccessRoles_Tb_UserPrivilege]
GO
