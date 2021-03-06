USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_RatingSettlement]    Script Date: 5/2/2020 6:27:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_RatingSettlement](
	[RatingSettlementID] [int] IDENTITY(1,1) NOT NULL,
	[RatingScenarioID] [int] NOT NULL,
	[Percentage] [decimal](8, 2) NOT NULL,
	[TariffTypeID] [int] NOT NULL,
	[ChargeTypeID] [int] NOT NULL,
	[RatePlanID] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_RatingSettlement] PRIMARY KEY CLUSTERED 
(
	[RatingSettlementID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_RatingSettlement] ADD  CONSTRAINT [DF_tb_RatingSettlement_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_RatingSettlement] ADD  CONSTRAINT [DF_tb_RatingSettlement_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_RatingSettlement]  WITH CHECK ADD  CONSTRAINT [FK_tb_RatingSettlement_tb_ChargeType] FOREIGN KEY([ChargeTypeID])
REFERENCES [dbo].[tb_ChargeType] ([ChargeTypeID])
GO
ALTER TABLE [dbo].[tb_RatingSettlement] CHECK CONSTRAINT [FK_tb_RatingSettlement_tb_ChargeType]
GO
ALTER TABLE [dbo].[tb_RatingSettlement]  WITH CHECK ADD  CONSTRAINT [FK_tb_RatingSettlement_tb_RatePlan] FOREIGN KEY([RatePlanID])
REFERENCES [dbo].[tb_RatePlan] ([RatePlanID])
GO
ALTER TABLE [dbo].[tb_RatingSettlement] CHECK CONSTRAINT [FK_tb_RatingSettlement_tb_RatePlan]
GO
ALTER TABLE [dbo].[tb_RatingSettlement]  WITH CHECK ADD  CONSTRAINT [FK_tb_RatingSettlement_tb_RatingScenario] FOREIGN KEY([RatingScenarioID])
REFERENCES [dbo].[tb_RatingScenario] ([RatingScenarioID])
GO
ALTER TABLE [dbo].[tb_RatingSettlement] CHECK CONSTRAINT [FK_tb_RatingSettlement_tb_RatingScenario]
GO
ALTER TABLE [dbo].[tb_RatingSettlement]  WITH CHECK ADD  CONSTRAINT [FK_tb_RatingSettlement_tb_TariffType] FOREIGN KEY([TariffTypeID])
REFERENCES [dbo].[tb_TariffType] ([TariffTypeID])
GO
ALTER TABLE [dbo].[tb_RatingSettlement] CHECK CONSTRAINT [FK_tb_RatingSettlement_tb_TariffType]
GO
