USE [UC_Admin]
GO
/****** Object:  Table [dbo].[wtb_PrivilegeAccessRoles]    Script Date: 5/2/2020 5:58:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[wtb_PrivilegeAccessRoles](
	[SessionID] [varchar](200) NOT NULL,
	[_Action] [varchar](100) NOT NULL,
	[UserPrivilegeID] [int] NOT NULL,
	[AccessRolesID] [int] NOT NULL
) ON [PRIMARY]
GO
