USE [UC_Facilitate]
GO
/****** Object:  Table [dbo].[tb_RoutingPlan]    Script Date: 5/2/2020 6:47:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_RoutingPlan](
	[Destination] [varchar](100) NULL,
	[Country] [varchar](100) NULL,
	[DialedDigit] [varchar](100) NULL
) ON [PRIMARY]
GO
