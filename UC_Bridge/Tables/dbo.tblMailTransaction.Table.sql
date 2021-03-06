USE [UC_Bridge]
GO
/****** Object:  Table [dbo].[tblMailTransaction]    Script Date: 5/2/2020 6:44:28 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblMailTransaction](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[EmailID] [bigint] NOT NULL,
	[DateReceived] [datetime] NULL,
	[StatusID] [int] NULL,
	[AcknowledgementSend] [nvarchar](5) NULL,
	[ProcessedStatusSend] [nvarchar](5) NULL,
	[InboxUniqueID] [bigint] NULL,
	[RegistrationUniqueID] [bigint] NULL,
	[RejectionUniqueID] [bigint] NULL,
	[ToBeProcessedUniqueID] [bigint] NULL,
	[ProcessedUniqueID] [bigint] NULL,
 CONSTRAINT [PK_tblMailTransaction] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
