USE [UC_Facilitate]
GO
/****** Object:  Table [dbo].[tb_CDRUploadStatistics]    Script Date: 5/2/2020 6:47:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_CDRUploadStatistics](
	[CDRFileName] [varchar](1000) NULL,
	[TotalRecords] [int] NULL,
	[UploadDate] [datetime] NULL
) ON [PRIMARY]
GO
