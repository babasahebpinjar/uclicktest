USE [UC_Bridge]
GO
/****** Object:  Table [dbo].[historyMailSender]    Script Date: 5/2/2020 6:44:26 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[historyMailSender](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ClientID] [int] NOT NULL,
	[EmailID] [bigint] NULL,
	[FromAddress] [nvarchar](150) NOT NULL,
	[ToAddress] [nvarchar](150) NOT NULL,
	[Cc] [nvarchar](2000) NULL,
	[Bcc] [nvarchar](2000) NULL,
	[Subject] [nvarchar](255) NULL,
	[Body] [ntext] NULL,
	[Attachment] [bit] NULL,
	[ErrorDetails] [ntext] NULL,
	[SentDate] [datetime] NULL,
	[ValidateType] [nvarchar](10) NULL,
	[UploadMessage] [nvarchar](5) NOT NULL,
 CONSTRAINT [PK_auditMailSender] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[historyMailSender] ADD  DEFAULT ('N') FOR [UploadMessage]
GO
ALTER TABLE [dbo].[historyMailSender]  WITH CHECK ADD  CONSTRAINT [fk_historyMailSender_EmailID] FOREIGN KEY([EmailID])
REFERENCES [dbo].[tblMailMaster] ([ID])
GO
ALTER TABLE [dbo].[historyMailSender] CHECK CONSTRAINT [fk_historyMailSender_EmailID]
GO
