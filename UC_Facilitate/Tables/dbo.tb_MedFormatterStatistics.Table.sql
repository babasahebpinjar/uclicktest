USE [UC_Facilitate]
GO
/****** Object:  Table [dbo].[tb_MedFormatterStatistics]    Script Date: 5/2/2020 6:47:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_MedFormatterStatistics](
	[CDRFileName] [varchar](200) NOT NULL,
	[TotalRecords] [int] NOT NULL,
	[TotalProcessedRecords] [int] NOT NULL,
	[TotalDuplicateRecords] [int] NOT NULL,
	[TotalRejectRecords] [int] NOT NULL,
	[TotalMinutes] [decimal](19, 2) NOT NULL,
	[TotalProcessedMinutes] [decimal](19, 2) NOT NULL,
	[TotalDuplicateMinutes] [decimal](19, 2) NOT NULL,
	[TotalRejectMinutes] [decimal](19, 2) NOT NULL,
	[FileStatus] [varchar](200) NOT NULL,
	[Remarks] [varchar](2000) NULL,
 CONSTRAINT [UC_tb_MedFormatterStatistics] UNIQUE NONCLUSTERED 
(
	[CDRFileName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
