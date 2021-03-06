USE [UC_Operations]
GO
/****** Object:  Table [dbo].[MS_TB_CDRExtract_Traffic_Summary]    Script Date: 5/2/2020 6:24:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MS_TB_CDRExtract_Traffic_Summary](
	[CallDate] [datetime] NULL,
	[CallHour] [int] NULL,
	[CallDuration] [int] NULL,
	[CallType] [varchar](60) NULL,
	[Answered] [int] NULL,
	[Seized] [int] NULL,
	[INAccount] [varchar](60) NULL,
	[OutAccount] [varchar](60) NULL,
	[INTrunkName] [varchar](60) NULL,
	[OutTrunkName] [varchar](60) NULL,
	[INCommercialTrunk] [varchar](60) NULL,
	[OUTCommercialTrunk] [varchar](60) NULL,
	[INDestination] [varchar](60) NULL,
	[OUTDestination] [varchar](60) NULL,
	[RoutingDestination] [varchar](60) NULL,
	[INServiceLevel] [varchar](60) NULL,
	[OutServiceLevel] [varchar](60) NULL,
	[INRatePlan] [varchar](60) NULL,
	[OutRatePlan] [varchar](60) NULL,
	[INRatingMethod] [varchar](100) NULL,
	[OUTRatingMethod] [varchar](100) NULL,
	[INROundedCallDuration] [int] NULL,
	[OutROundedCallDuration] [int] NULL,
	[INChargeDuration] [numeric](38, 4) NULL,
	[OUTChargeDuration] [numeric](38, 4) NULL,
	[INAmount] [numeric](38, 6) NULL,
	[OUTAmount] [numeric](38, 6) NULL,
	[INRate] [numeric](38, 6) NULL,
	[OutRate] [numeric](38, 6) NULL,
	[INErrorFlag] [int] NULL,
	[OUTErrorFlag] [int] NULL,
	[INError] [varchar](200) NULL,
	[OUTError] [varchar](200) NULL
) ON [PRIMARY]
GO
