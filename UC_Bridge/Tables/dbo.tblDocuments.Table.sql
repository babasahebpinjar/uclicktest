USE [UC_Bridge]
GO
/****** Object:  Table [dbo].[tblDocuments]    Script Date: 5/2/2020 6:44:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblDocuments](
	[ID] [bigint] NOT NULL,
	[EmailID] [bigint] NOT NULL,
	[FileName] [nvarchar](255) NULL,
	[FileSize] [int] NULL,
	[SubFolderPath] [nvarchar](500) NULL,
	[StatusID] [int] NOT NULL,
	[StatusReasonCode] [nvarchar](2000) NULL,
	[OutputFileName] [nvarchar](255) NULL,
	[OutputSubFolderPath] [nvarchar](500) NULL,
	[OutputCreatedDate] [datetime] NULL,
	[IsFileNameChanged] [bit] NOT NULL,
 CONSTRAINT [PK_tblDocuments] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tblDocuments] ADD  DEFAULT ((0)) FOR [IsFileNameChanged]
GO
ALTER TABLE [dbo].[tblDocuments]  WITH CHECK ADD  CONSTRAINT [fk_tblDocuments_EmailID] FOREIGN KEY([EmailID])
REFERENCES [dbo].[tblMailMaster] ([ID])
GO
ALTER TABLE [dbo].[tblDocuments] CHECK CONSTRAINT [fk_tblDocuments_EmailID]
GO
