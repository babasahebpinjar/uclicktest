USE [UC_Bridge]
GO
/****** Object:  Table [dbo].[tblOfferType]    Script Date: 5/2/2020 6:44:28 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblOfferType](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ClientID] [int] NOT NULL,
	[Code] [nvarchar](5) NOT NULL,
	[Description] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_tblOfferType] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
