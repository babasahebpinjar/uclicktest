USE [UC_Bridge]
GO
/****** Object:  Table [dbo].[tblMailTemplates]    Script Date: 5/2/2020 6:44:28 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblMailTemplates](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ClientID] [int] NULL,
	[StatusID] [int] NULL,
	[Subject] [nvarchar](4000) NULL,
	[Body] [ntext] NULL,
	[Status] [bit] NULL,
 CONSTRAINT [PK_tblMailTemplates] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[tblMailTemplates]  WITH CHECK ADD  CONSTRAINT [fk_tblMailTemplates_ClientID] FOREIGN KEY([ClientID])
REFERENCES [dbo].[tblClientMaster] ([ID])
GO
ALTER TABLE [dbo].[tblMailTemplates] CHECK CONSTRAINT [fk_tblMailTemplates_ClientID]
GO
ALTER TABLE [dbo].[tblMailTemplates]  WITH CHECK ADD  CONSTRAINT [fk_tblMailTemplates_StatusID] FOREIGN KEY([StatusID])
REFERENCES [dbo].[tblStatusMaster] ([ID])
GO
ALTER TABLE [dbo].[tblMailTemplates] CHECK CONSTRAINT [fk_tblMailTemplates_StatusID]
GO
