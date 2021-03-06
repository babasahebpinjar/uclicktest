USE [UC_Facilitate]
GO
/****** Object:  Table [dbo].[tb_CDRFileDataAnalyzed]    Script Date: 5/2/2020 6:47:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_CDRFileDataAnalyzed](
	[INTrunk] [varchar](50) NULL,
	[OUTTrunk] [varchar](50) NULL,
	[CallingNumber] [varchar](50) NULL,
	[CalledNumber] [varchar](50) NULL,
	[CallDate] [date] NULL,
	[CallHour] [int] NULL,
	[CallMinute] [int] NULL,
	[CallSecond] [int] NULL,
	[CircuitDuration] [int] NULL,
	[CallDuration] [int] NULL,
	[ReleaseCause] [int] NULL,
	[CDRFileName] [varchar](1000) NULL,
	[RecordID] [int] IDENTITY(1,1) NOT NULL,
	[INAccount] [varchar](100) NULL,
	[OUTAccount] [varchar](100) NULL,
	[Country] [varchar](100) NULL,
	[OutCountry] [varchar](100) NULL,
	[Destination] [varchar](100) NULL,
	[OutDestination] [varchar](100) NULL,
	[INRate] [decimal](19, 6) NULL,
	[OUTRate] [decimal](19, 6) NULL,
	[CallDurationMinutes] [decimal](19, 4) NULL,
	[INAmount] [decimal](19, 4) NULL,
	[OUTAmount] [decimal](19, 4) NULL
) ON [PRIMARY]
GO
