USE [UC_Commerce]
GO
/****** Object:  Table [dbo].[tb_UIChartOfferTrendLastNMonths]    Script Date: 5/2/2020 6:14:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_UIChartOfferTrendLastNMonths](
	[OfferContent] [varchar](50) NULL,
	[MonthYear] [varchar](10) NULL,
	[YearMonthNum] [int] NULL,
	[TotalOffers] [int] NULL
) ON [PRIMARY]
GO
