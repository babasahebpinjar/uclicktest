USE [UC_Reference]
GO
/****** Object:  Table [dbo].[TempRoutingDestination]    Script Date: 5/2/2020 6:27:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TempRoutingDestination](
	[Destination] [varchar](60) NULL,
	[DestinationAbbrv] [varchar](30) NULL,
	[DestinationType] [varchar](30) NULL,
	[Country] [varchar](100) NULL,
	[DDBreakout] [varchar](30) NULL,
	[ResolvedCountry] [varchar](500) NULL,
	[Remarks] [varchar](500) NULL
) ON [PRIMARY]
GO
