USE [UC_Commerce]
GO
/****** Object:  Table [dbo].[tb_UIChartAverageOfferProcessTimeByContent]    Script Date: 5/2/2020 6:14:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_UIChartAverageOfferProcessTimeByContent](
	[OfferContent] [varchar](50) NULL,
	[AverageProcessTimeMin] [int] NULL
) ON [PRIMARY]
GO
