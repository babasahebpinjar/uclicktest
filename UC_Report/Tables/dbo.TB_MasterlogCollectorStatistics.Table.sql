USE [UC_Report]
GO
/****** Object:  Table [dbo].[TB_MasterlogCollectorStatistics]    Script Date: 5/2/2020 6:38:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_MasterlogCollectorStatistics](
	[MasterlogFileName] [varchar](200) NOT NULL,
	[CompressFileSizeInBytes] [varchar](200) NOT NULL,
	[UnCompressFileSizeInBytes] [varchar](200) NOT NULL,
	[FileTimeStamp] [varchar](100) NOT NULL,
	[FileStatus] [varchar](200) NOT NULL,
	[Remarks] [varchar](1000) NULL
) ON [PRIMARY]
GO
