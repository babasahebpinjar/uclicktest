USE [UC_Bridge]
GO
/****** Object:  Table [dbo].[tblIncomingMailSettings]    Script Date: 5/2/2020 6:44:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblIncomingMailSettings](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ClientID] [int] NOT NULL,
	[LicenseKey] [nvarchar](50) NULL,
	[ServerName] [nvarchar](50) NOT NULL,
	[AccountName] [nvarchar](150) NOT NULL,
	[Password] [nvarchar](50) NOT NULL,
	[FolderName] [nvarchar](50) NOT NULL,
	[MoveFolderName] [nvarchar](50) NULL,
	[SpamFolderName] [nvarchar](50) NULL,
	[RejectionMoveFolderName] [nvarchar](50) NULL,
	[TobeProcessedFolderName] [nvarchar](50) NULL,
	[ProcessedFolderName] [nvarchar](50) NULL,
	[PortNumber] [int] NULL,
	[SSL] [bit] NOT NULL,
	[MailLastUID] [bigint] NULL,
	[MailStartDate] [datetime] NULL,
	[Status] [int] NOT NULL,
	[SentFolderName] [nvarchar](50) NULL,
	[ProxyServerName] [nvarchar](50) NULL,
	[ProxyServerPort] [nvarchar](5) NULL,
 CONSTRAINT [PK_tblIncomingMailSettings_1] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
