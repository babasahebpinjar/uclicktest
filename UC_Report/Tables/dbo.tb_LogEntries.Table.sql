USE [UC_Report]
GO
/****** Object:  Table [dbo].[tb_LogEntries]    Script Date: 5/2/2020 6:38:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_LogEntries](
	[LogDate] [datetime] NULL,
	[CallID] [varchar](100) NULL,
	[CallingNumber] [varchar](100) NULL,
	[CalledNumber] [varchar](100) NULL,
	[LogFilename] [varchar](100) NULL,
	[ServerName] [varchar](100) NULL,
	[RecordsCount] [int] NULL,
	[MasterLogName] [varchar](100) NULL
) ON [PRIMARY]
GO
