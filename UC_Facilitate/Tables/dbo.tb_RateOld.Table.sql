USE [UC_Facilitate]
GO
/****** Object:  Table [dbo].[tb_RateOld]    Script Date: 5/2/2020 6:47:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_RateOld](
	[Account] [varchar](100) NULL,
	[Destination] [varchar](100) NULL,
	[Rate] [decimal](19, 6) NULL,
	[Direction] [varchar](100) NULL
) ON [PRIMARY]
GO
