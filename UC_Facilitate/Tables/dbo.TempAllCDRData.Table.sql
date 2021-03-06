USE [UC_Facilitate]
GO
/****** Object:  Table [dbo].[TempAllCDRData]    Script Date: 5/2/2020 6:47:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TempAllCDRData](
	[CDRFileName] [varchar](500) NULL,
	[CallingNumber] [varchar](50) NULL,
	[CalledNumber] [varchar](50) NULL,
	[CallDuration] [int] NULL,
	[Destination] [varchar](100) NULL,
	[CallDate] [datetime] NULL
) ON [PRIMARY]
GO
