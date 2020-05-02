USE [UC_Bridge]
GO
/****** Object:  Table [dbo].[tb_UsersPasswordList]    Script Date: 5/2/2020 6:44:26 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_UsersPasswordList](
	[UserPasswordListID] [int] IDENTITY(1,1) NOT NULL,
	[UserID] [int] NOT NULL,
	[Password] [varbinary](100) NOT NULL,
 CONSTRAINT [PK_tb_UsersPasswordList] PRIMARY KEY CLUSTERED 
(
	[UserPasswordListID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
