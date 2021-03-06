USE [UC_Report]
GO
/****** Object:  Table [dbo].[MS_TB_CDRExtract_Traffic]    Script Date: 5/2/2020 6:38:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MS_TB_CDRExtract_Traffic](
	[ObjectInstanceID] [int] NULL,
	[CallDate] [date] NULL,
	[CallHour] [int] NULL,
	[CallDuration] [int] NULL,
	[CallingNumber] [varchar](30) NULL,
	[CalledNumber] [varchar](100) NULL,
	[OriginalCalledNumber] [varchar](100) NULL,
	[Answered] [int] NULL,
	[CallType] [varchar](60) NULL,
	[INAccount] [varchar](60) NULL,
	[OutAccount] [varchar](60) NULL,
	[INTrunkName] [varchar](91) NULL,
	[OutTrunkName] [varchar](91) NULL,
	[INCommercialTrunk] [varchar](60) NULL,
	[OUTCOmmercialTrunk] [varchar](60) NULL,
	[INDestination] [varchar](60) NULL,
	[OUTDestination] [varchar](60) NULL,
	[RoutingDestination] [varchar](60) NULL,
	[INServiceLevel] [varchar](60) NULL,
	[OUTServiceLevel] [varchar](60) NULL,
	[INErrorFlag] [int] NULL,
	[OUTErrorFlag] [int] NULL,
	[InternalFileName] [varchar](100) NULL
) ON [PRIMARY]
GO
