USE [UC_Bridge]
GO
/****** Object:  Table [dbo].[tblMailMaster]    Script Date: 5/2/2020 6:44:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblMailMaster](
	[ID] [bigint] NOT NULL,
	[ClientID] [int] NOT NULL,
	[FromAddress] [nvarchar](150) NOT NULL,
	[Cc] [nvarchar](2000) NULL,
	[Bcc] [nvarchar](2000) NULL,
	[Subject] [nvarchar](255) NULL,
	[Body] [ntext] NULL,
	[AttachmentsCount] [int] NOT NULL,
	[DateReceived] [datetime] NULL,
	[StatusID] [int] NOT NULL,
	[StatusReasonCode] [nvarchar](2000) NULL,
	[CreatedDate] [datetime] NULL,
	[ProcessedDate] [datetime] NULL,
	[EmailUniqueId] [bigint] NULL,
	[DocumentProcessedStatus] [int] NULL,
	[VendorDetailsID] [int] NULL,
 CONSTRAINT [PK_tblMailMaster] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[tblMailMaster] ADD  CONSTRAINT [DF_tblMailMaster_VendorID]  DEFAULT ((0)) FOR [VendorDetailsID]
GO
