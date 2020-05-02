USE [UC_Admin]
GO
/****** Object:  Table [dbo].[tb_UserStatus]    Script Date: 02-05-2020 14:39:21 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_UserStatus](
	[UserStatusID] [int] IDENTITY(1,1) NOT NULL,
	[UserStatus] [varchar](50) NOT NULL,
 CONSTRAINT [PK_tb_UserStatus] PRIMARY KEY CLUSTERED 
(
	[UserStatusID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [uc_UserStatus] UNIQUE NONCLUSTERED 
(
	[UserStatus] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
