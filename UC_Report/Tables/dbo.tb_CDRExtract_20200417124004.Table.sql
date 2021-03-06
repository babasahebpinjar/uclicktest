USE [UC_Report]
GO
/****** Object:  Table [dbo].[tb_CDRExtract_20200417124004]    Script Date: 5/2/2020 6:38:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_CDRExtract_20200417124004](
	[CallDate] [date] NULL,
	[CallTime] [varchar](8) NULL,
	[CallingNumber] [varchar](30) NULL,
	[CalledNumber] [varchar](100) NULL,
	[CallDuration] [int] NULL,
	[INAccount] [varchar](60) NOT NULL,
	[OUTAccount] [varchar](60) NOT NULL,
	[RoutingDestination] [varchar](60) NOT NULL,
	[INServiceLevel] [varchar](60) NOT NULL,
	[OUTServiceLevel] [varchar](60) NOT NULL,
	[INErrorFlag] [varchar](33) NULL,
	[OUTErrorFlag] [varchar](33) NULL
) ON [PRIMARY]
GO
