USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_AxiataReplaceTrunk]    Script Date: 5/2/2020 6:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_AxiataReplaceTrunk](
	[AxiataReplaceTrunkID] [int] IDENTITY(1,1) NOT NULL,
	[INTrunkName] [varchar](100) NULL,
	[ReplaceInTrunkName] [varchar](100) NULL,
	[BeginDate] [datetime] NULL,
	[EndDate] [datetime] NULL
) ON [PRIMARY]
GO
