USE [UC_Report]
GO
/****** Object:  Table [dbo].[tb_HourlyINCrossOutTrafficMart]    Script Date: 5/2/2020 6:38:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_HourlyINCrossOutTrafficMart](
	[CallDate] [datetime] NULL,
	[CallHour] [int] NULL,
	[CallDuration] [int] NULL,
	[CircuitDuration] [int] NULL,
	[Answered] [int] NULL,
	[Seized] [int] NULL,
	[CallTypeID] [int] NULL,
	[INAccountID] [int] NULL,
	[OutAccountID] [int] NULL,
	[INTrunkID] [int] NULL,
	[OutTrunkID] [int] NULL,
	[INCommercialTrunkID] [int] NULL,
	[OUTCOmmercialTrunkID] [int] NULL,
	[INDestinationID] [int] NULL,
	[OUTDestinationID] [int] NULL,
	[RoutingDestinationID] [int] NULL,
	[INServiceLevelID] [int] NULL,
	[OUTServiceLevelID] [int] NULL,
	[INRoundedCallDuration] [int] NULL,
	[OutRoundedCallDuration] [int] NULL,
	[INChargeDuration] [decimal](19, 4) NULL,
	[OUTChargeDuration] [decimal](19, 4) NULL
) ON [PRIMARY]
GO
