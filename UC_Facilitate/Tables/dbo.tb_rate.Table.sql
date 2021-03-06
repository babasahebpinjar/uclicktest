USE [UC_Facilitate]
GO
/****** Object:  Table [dbo].[tb_rate]    Script Date: 5/2/2020 6:47:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_rate](
	[Account] [varchar](30) NOT NULL,
	[Destination] [varchar](60) NOT NULL,
	[Rate] [numeric](19, 6) NOT NULL,
	[BeginDate] [datetime] NOT NULL,
	[EndDate] [datetime] NULL,
	[Direction] [varchar](8) NOT NULL
) ON [PRIMARY]
GO
