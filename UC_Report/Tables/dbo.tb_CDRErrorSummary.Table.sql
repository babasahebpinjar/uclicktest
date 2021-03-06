USE [UC_Report]
GO
/****** Object:  Table [dbo].[tb_CDRErrorSummary]    Script Date: 5/2/2020 6:38:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_CDRErrorSummary](
	[DirectionID] [int] NULL,
	[CallDate] [datetime] NULL,
	[CallDuration] [decimal](19, 4) NULL,
	[CalledNumber] [varchar](10) NULL,
	[OriginalCalledNumber] [varchar](10) NULL,
	[Answered] [int] NULL,
	[Seized] [int] NULL,
	[CallTypeID] [int] NULL,
	[AccountID] [int] NULL,
	[TrunkID] [int] NULL,
	[TrunkName] [varchar](60) NULL,
	[CommercialTrunkID] [int] NULL,
	[DestinationID] [int] NULL,
	[RoutingDestinationID] [int] NULL,
	[ServiceLevelID] [int] NULL,
	[RatePlanID] [int] NULL,
	[NumberPlanID] [int] NULL,
	[ErrorType] [int] NULL
) ON [PRIMARY]
GO
