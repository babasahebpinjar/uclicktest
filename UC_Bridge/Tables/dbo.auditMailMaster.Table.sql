USE [UC_Bridge]
GO
/****** Object:  Table [dbo].[auditMailMaster]    Script Date: 5/2/2020 6:44:26 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[auditMailMaster](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[EmailID] [bigint] NULL,
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
	[EmailRefNo] [nvarchar](1000) NULL,
	[VendorDetailsID] [int] NULL,
	[AuditAction] [nvarchar](50) NULL,
	[AuditDate] [datetime] NULL,
 CONSTRAINT [PK_auditMailMaster] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[auditMailMaster] ADD  CONSTRAINT [DF_auditMailMaster_VendorDetailsID]  DEFAULT ((0)) FOR [VendorDetailsID]
GO
ALTER TABLE [dbo].[auditMailMaster]  WITH CHECK ADD  CONSTRAINT [fk_auditMailMaster_EmailID] FOREIGN KEY([EmailID])
REFERENCES [dbo].[tblMailMaster] ([ID])
GO
ALTER TABLE [dbo].[auditMailMaster] CHECK CONSTRAINT [fk_auditMailMaster_EmailID]
GO
