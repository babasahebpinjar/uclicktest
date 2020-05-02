USE [UC_Bridge]
GO
/****** Object:  Table [dbo].[tblAppSettings]    Script Date: 5/2/2020 6:44:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblAppSettings](
	[ClientID] [int] NULL,
	[KeyName] [nvarchar](50) NULL,
	[Description] [nvarchar](500) NULL,
	[Value] [nvarchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
