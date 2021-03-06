USE [UC_Bridge]
GO
/****** Object:  Table [dbo].[tb_Users]    Script Date: 5/2/2020 6:44:26 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_Users](
	[UserID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](30) NOT NULL,
	[EmailID] [varchar](100) NOT NULL,
	[Password] [varbinary](100) NOT NULL,
	[UserPrivilegeID] [int] NOT NULL,
	[UserStatusID] [int] NOT NULL,
	[LoginAttempts] [int] NULL,
	[LastPasswordDate] [date] NOT NULL,
 CONSTRAINT [PK_tb_Users] PRIMARY KEY CLUSTERED 
(
	[UserID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [uc_EmailID] UNIQUE NONCLUSTERED 
(
	[EmailID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_Users] ADD  DEFAULT (getdate()) FOR [LastPasswordDate]
GO
