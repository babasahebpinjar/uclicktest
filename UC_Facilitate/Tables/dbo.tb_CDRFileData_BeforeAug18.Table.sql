USE [UC_Facilitate]
GO
/****** Object:  Table [dbo].[tb_CDRFileData_BeforeAug18]    Script Date: 5/2/2020 6:47:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_CDRFileData_BeforeAug18](
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
	[CDRFileName] [varchar](1000) NULL
) ON [PRIMARY]
GO
