USE [UC_Operations]
GO
/****** Object:  Table [dbo].[tb_LoadBalancingRange]    Script Date: 5/2/2020 6:24:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_LoadBalancingRange](
	[LoadBalancingRangeValue] [int] NOT NULL,
	[CDRFileObjectID] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
 CONSTRAINT [PK_tb_LoadBalancingRange] PRIMARY KEY CLUSTERED 
(
	[LoadBalancingRangeValue] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_LoadBalancingRange] UNIQUE NONCLUSTERED 
(
	[LoadBalancingRangeValue] ASC,
	[CDRFileObjectID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
