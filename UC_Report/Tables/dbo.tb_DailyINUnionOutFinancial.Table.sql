USE [UC_Report]
GO
/****** Object:  Table [dbo].[tb_DailyINUnionOutFinancial]    Script Date: 5/2/2020 6:38:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_DailyINUnionOutFinancial](
	[CallDate] [datetime] NULL,
	[DirectionID] [int] NULL,
	[CallDuration] [int] NULL,
	[CircuitDuration] [int] NULL,
	[Answered] [int] NULL,
	[Seized] [int] NULL,
	[CallTypeID] [int] NULL,
	[AccountID] [int] NULL,
	[TrunkID] [int] NULL,
	[CommercialTrunkID] [int] NULL,
	[SettlementDestinationID] [int] NULL,
	[RoutingDestinationID] [int] NULL,
	[INServiceLevelID] [int] NULL,
	[OUTServiceLevelID] [int] NULL,
	[RatePlanID] [int] NULL,
	[RatingMethodID] [int] NULL,
	[RoundedCallDuration] [int] NULL,
	[ChargeDuration] [decimal](19, 4) NULL,
	[Amount] [decimal](19, 6) NULL,
	[Rate] [decimal](19, 6) NULL,
	[RateTypeID] [int] NULL,
	[CurrencyID] [int] NULL,
	[ErrorIndicator] [int] NULL
) ON [PRIMARY]
GO
