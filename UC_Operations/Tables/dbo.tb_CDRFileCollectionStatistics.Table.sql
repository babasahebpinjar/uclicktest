USE [UC_Operations]
GO
/****** Object:  Table [dbo].[tb_CDRFileCollectionStatistics]    Script Date: 5/2/2020 6:24:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_CDRFileCollectionStatistics](
	[CDRFileName] [varchar](200) NOT NULL,
	[FileCollectDate] [datetime] NOT NULL,
	[OriginalFileSizeInKB] [decimal](19, 2) NOT NULL,
	[CollectFileSizeInKB] [decimal](19, 2) NOT NULL,
	[CDRCollectionProcessInstanceID] [int] NOT NULL,
	[CDRLoadObjectID] [int] NOT NULL
) ON [PRIMARY]
GO
