USE [UC_Bridge]
GO
/****** Object:  Table [dbo].[tblOutgoingMailSettings]    Script Date: 5/2/2020 6:44:28 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblOutgoingMailSettings](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ClientID] [int] NOT NULL,
	[ServerName] [nvarchar](50) NOT NULL,
	[AccountName] [nvarchar](150) NOT NULL,
	[Password] [nvarchar](50) NOT NULL,
	[FromAddress] [nvarchar](150) NOT NULL,
	[PortNumber] [int] NULL,
	[SSL] [bit] NOT NULL,
	[Status] [int] NOT NULL,
	[ProxyServerName] [nvarchar](50) NULL,
	[ProxyServerPort] [nvarchar](5) NULL,
 CONSTRAINT [PK_tblOutgoingMailSettings] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tblOutgoingMailSettings]  WITH CHECK ADD  CONSTRAINT [fk_tblOutGoingMailSettings_ClientID] FOREIGN KEY([ClientID])
REFERENCES [dbo].[tblClientMaster] ([ID])
GO
ALTER TABLE [dbo].[tblOutgoingMailSettings] CHECK CONSTRAINT [fk_tblOutGoingMailSettings_ClientID]
GO
