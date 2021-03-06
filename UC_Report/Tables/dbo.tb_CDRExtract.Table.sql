USE [UC_Report]
GO
/****** Object:  Table [dbo].[tb_CDRExtract]    Script Date: 5/2/2020 6:38:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_CDRExtract](
	[CDRExtractID] [int] IDENTITY(1,1) NOT NULL,
	[CDRExtractName] [varchar](500) NOT NULL,
	[UserID] [int] NOT NULL,
	[CDRExtractStatusID] [int] NOT NULL,
	[CDRExtractFileName] [varchar](500) NULL,
	[CDRExtractRequestDate] [datetime] NOT NULL,
	[CDRExtractCompletionDate] [datetime] NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Remarks] [varchar](2000) NULL,
 CONSTRAINT [PK_tb_CDRExtract] PRIMARY KEY CLUSTERED 
(
	[CDRExtractID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_CDRExtract] UNIQUE NONCLUSTERED 
(
	[UserID] ASC,
	[CDRExtractName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_CDRExtract]  WITH CHECK ADD  CONSTRAINT [FK_tb_CDRExtract_tb_CDRExtractStatus] FOREIGN KEY([CDRExtractStatusID])
REFERENCES [dbo].[tb_CDRExtractStatus] ([CDRExtractStatusID])
GO
ALTER TABLE [dbo].[tb_CDRExtract] CHECK CONSTRAINT [FK_tb_CDRExtract_tb_CDRExtractStatus]
GO
