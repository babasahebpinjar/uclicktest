USE [UC_Bridge]
GO
/****** Object:  Table [dbo].[tblDocumentType]    Script Date: 5/2/2020 6:44:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblDocumentType](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ClientID] [int] NOT NULL,
	[Description] [nvarchar](50) NULL,
 CONSTRAINT [PK_tblDocumentType] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tblDocumentType]  WITH CHECK ADD  CONSTRAINT [fk_tblDocumentType_ClientID] FOREIGN KEY([ClientID])
REFERENCES [dbo].[tblClientMaster] ([ID])
GO
ALTER TABLE [dbo].[tblDocumentType] CHECK CONSTRAINT [fk_tblDocumentType_ClientID]
GO
