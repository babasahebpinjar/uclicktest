USE [UC_Facilitate]
GO
/****** Object:  Table [dbo].[tb_TrunkToAccountMapping]    Script Date: 5/2/2020 6:47:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_TrunkToAccountMapping](
	[Trunk] [varchar](200) NULL,
	[Account] [varchar](100) NULL
) ON [PRIMARY]
GO
