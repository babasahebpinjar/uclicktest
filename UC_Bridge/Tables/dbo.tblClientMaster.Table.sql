USE [UC_Bridge]
GO
/****** Object:  Table [dbo].[tblClientMaster]    Script Date: 5/2/2020 6:44:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblClientMaster](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[EmailID] [nvarchar](150) NULL,
	[Logo] [nvarchar](255) NULL,
	[MailServer] [nvarchar](5) NOT NULL,
	[Status] [int] NOT NULL,
 CONSTRAINT [PK_tblClientMaster] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
