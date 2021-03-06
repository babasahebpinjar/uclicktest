USE [UC_Bridge]
GO
/****** Object:  Table [dbo].[tblErrorNotificationCodes]    Script Date: 5/2/2020 6:44:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblErrorNotificationCodes](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ClientID] [int] NULL,
	[Category] [nvarchar](50) NULL,
	[Code] [nvarchar](50) NULL,
	[Title] [nvarchar](1000) NULL,
	[Keyword] [nvarchar](500) NULL,
 CONSTRAINT [PK_tblErrorNotificationCodes] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
