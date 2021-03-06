USE [UC_Bridge]
GO
/****** Object:  Table [dbo].[auditDocuments]    Script Date: 5/2/2020 6:44:26 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[auditDocuments](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[DocumentID] [bigint] NULL,
	[EmailID] [bigint] NOT NULL,
	[FileName] [nvarchar](255) NULL,
	[FileSize] [int] NULL,
	[SubFolderPath] [nvarchar](500) NULL,
	[StatusID] [int] NOT NULL,
	[StatusReasonCode] [nvarchar](2000) NULL,
	[OutputFileName] [nvarchar](255) NULL,
	[OutputSubFolderPath] [nvarchar](500) NULL,
	[OutputCreatedDate] [datetime] NULL,
	[AuditAction] [nvarchar](50) NULL,
	[AuditDate] [datetime] NULL,
	[IsFileNameChanged] [bit] NOT NULL,
 CONSTRAINT [PK_auditDocuments] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[auditDocuments] ADD  DEFAULT ((0)) FOR [IsFileNameChanged]
GO
ALTER TABLE [dbo].[auditDocuments]  WITH CHECK ADD  CONSTRAINT [fk_auditDocuments_DocumentID] FOREIGN KEY([DocumentID])
REFERENCES [dbo].[tblDocuments] ([ID])
GO
ALTER TABLE [dbo].[auditDocuments] CHECK CONSTRAINT [fk_auditDocuments_DocumentID]
GO
