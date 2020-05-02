USE [UC_Reference]
GO
/****** Object:  Table [dbo].[Temp_Country]    Script Date: 5/2/2020 6:27:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Temp_Country](
	[Country] [varchar](60) NULL,
	[CountryAbbrv] [varchar](20) NULL,
	[CountryCode] [varchar](100) NULL,
	[CountryType] [varchar](100) NULL
) ON [PRIMARY]
GO
