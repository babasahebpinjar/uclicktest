USE [UC_Bridge]
GO
/****** Object:  Table [dbo].[tblMailSender]    Script Date: 5/2/2020 6:44:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblMailSender](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
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
 CONSTRAINT [PK_tblMailSender] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[tblMailSender]  WITH CHECK ADD  CONSTRAINT [fk_tblMailSender_EmailID] FOREIGN KEY([EmailID])
REFERENCES [dbo].[tblMailMaster] ([ID])
GO
ALTER TABLE [dbo].[tblMailSender] CHECK CONSTRAINT [fk_tblMailSender_EmailID]
GO
