USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_RatePlan]    Script Date: 5/2/2020 6:27:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_RatePlan](
	[RatePlanID] [int] IDENTITY(1,1) NOT NULL,
	[RatePlan] [varchar](60) NOT NULL,
	[RatePlanAbbrv] [varchar](50) NOT NULL,
	[AgreementID] [int] NOT NULL,
	[DirectionID] [int] NOT NULL,
	[RatePlanGroupID] [int] NULL,
	[CurrencyID] [int] NOT NULL,
	[ProductCataLogID] [int] NOT NULL,
	[IncreaseNoticePeriod] [int] NULL,
	[DecreaseNoticePeriod] [int] NULL,
	[BeginDate] [datetime] NOT NULL,
	[EndDate] [datetime] NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_RatePlan] PRIMARY KEY CLUSTERED 
(
	[RatePlanID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_RatePlan] UNIQUE NONCLUSTERED 
(
	[RatePlan] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_RatePlan] ADD  CONSTRAINT [DF_tb_RatePlan_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_RatePlan] ADD  CONSTRAINT [DF_tb_RatePlan_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_RatePlan]  WITH CHECK ADD  CONSTRAINT [FK_tb_RatePlan_tb_Agreement] FOREIGN KEY([AgreementID])
REFERENCES [dbo].[tb_Agreement] ([AgreementID])
GO
ALTER TABLE [dbo].[tb_RatePlan] CHECK CONSTRAINT [FK_tb_RatePlan_tb_Agreement]
GO
ALTER TABLE [dbo].[tb_RatePlan]  WITH CHECK ADD  CONSTRAINT [FK_tb_RatePlan_tb_Currency] FOREIGN KEY([CurrencyID])
REFERENCES [dbo].[tb_Currency] ([CurrencyID])
GO
ALTER TABLE [dbo].[tb_RatePlan] CHECK CONSTRAINT [FK_tb_RatePlan_tb_Currency]
GO
ALTER TABLE [dbo].[tb_RatePlan]  WITH CHECK ADD  CONSTRAINT [FK_tb_RatePlan_tb_Direction] FOREIGN KEY([DirectionID])
REFERENCES [dbo].[tb_Direction] ([DirectionID])
GO
ALTER TABLE [dbo].[tb_RatePlan] CHECK CONSTRAINT [FK_tb_RatePlan_tb_Direction]
GO
ALTER TABLE [dbo].[tb_RatePlan]  WITH CHECK ADD  CONSTRAINT [FK_tb_RatePlan_tb_ProductCatalog] FOREIGN KEY([ProductCataLogID])
REFERENCES [dbo].[tb_ProductCatalog] ([ProductCatalogID])
GO
ALTER TABLE [dbo].[tb_RatePlan] CHECK CONSTRAINT [FK_tb_RatePlan_tb_ProductCatalog]
GO
ALTER TABLE [dbo].[tb_RatePlan]  WITH CHECK ADD  CONSTRAINT [FK_tb_RatePlan_tb_RatePlanGroup] FOREIGN KEY([RatePlanGroupID])
REFERENCES [dbo].[tb_RatePlanGroup] ([RatePlanGroupID])
GO
ALTER TABLE [dbo].[tb_RatePlan] CHECK CONSTRAINT [FK_tb_RatePlan_tb_RatePlanGroup]
GO
