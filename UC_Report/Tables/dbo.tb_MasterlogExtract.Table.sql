USE [UC_Report]
GO
/****** Object:  Table [dbo].[tb_MasterlogExtract]    Script Date: 5/2/2020 6:38:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_MasterlogExtract](
	[MasterlogExtractId] [int] IDENTITY(1,1) NOT NULL,
	[MasterlogExtractName] [varchar](100) NULL,
	[MasterlogExtractDescription] [varchar](100) NULL,
	[MasterlogExtractFilename] [varchar](100) NULL,
	[MasterlogExtractRequestDate] [datetime] NULL,
	[MasterlogExtractCompletionDate] [datetime] NULL,
	[Remarks] [varchar](max) NULL,
	[UserID] [int] NULL,
	[MasterlogExtractStatusID] [int] NULL,
	[ModifiedDate] [datetime] NULL,
	[ModifiedByID] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[MasterlogExtractId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
