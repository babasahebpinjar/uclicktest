USE [UC_Facilitate]
GO
/****** Object:  Table [dbo].[tb_MedConverterStatistics]    Script Date: 5/2/2020 6:47:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_MedConverterStatistics](
	[CDRFileName] [varchar](200) NULL,
	[TotalRecords] [int] NULL,
	[TotalOutputRecords] [int] NULL,
	[ProcessStartTime] [datetime] NULL,
	[TotalProcessTime] [int] NULL,
	[FileStatus] [varchar](200) NULL,
	[Remarks] [varchar](1000) NULL
) ON [PRIMARY]
GO
