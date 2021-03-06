USE [UC_Bridge]
GO
/****** Object:  Table [dbo].[tblMailAttachments]    Script Date: 5/2/2020 6:44:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblMailAttachments](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[EmailID] [bigint] NULL,
	[FilePath] [nvarchar](2000) NULL,
	[CreatedDate] [datetime] NULL,
 CONSTRAINT [PK_tblMailAttachments] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tblMailAttachments]  WITH CHECK ADD  CONSTRAINT [fk_tblMailAttachments_EmailID] FOREIGN KEY([EmailID])
REFERENCES [dbo].[tblMailMaster] ([ID])
GO
ALTER TABLE [dbo].[tblMailAttachments] CHECK CONSTRAINT [fk_tblMailAttachments_EmailID]
GO
