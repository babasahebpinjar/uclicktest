USE [UC_Bridge]
GO
/****** Object:  Table [dbo].[tblErrorNotificationDetails]    Script Date: 5/2/2020 6:44:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblErrorNotificationDetails](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Category] [nvarchar](100) NULL,
	[MethodName] [nvarchar](100) NULL,
	[Title] [nvarchar](1000) NULL,
	[Message] [nvarchar](max) NULL,
	[Description] [nvarchar](max) NULL,
	[IsSentMail] [nvarchar](5) NULL,
	[CreatedDate] [datetime] NULL,
 CONSTRAINT [PK_tblErrorNotification] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
