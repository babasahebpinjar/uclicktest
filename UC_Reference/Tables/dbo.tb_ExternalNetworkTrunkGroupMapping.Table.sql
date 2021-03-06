USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_ExternalNetworkTrunkGroupMapping]    Script Date: 5/2/2020 6:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_ExternalNetworkTrunkGroupMapping](
	[TrunkID] [int] NOT NULL,
	[VirtualNetworkID] [int] NOT NULL,
	[TrunkGroupID] [int] NOT NULL,
	[TrunkGroupName] [nvarchar](50) NOT NULL,
	[CRFRouteProfileID] [int] NOT NULL,
	[BlockStatus] [int] NOT NULL
) ON [PRIMARY]
GO
