USE [UC_Bridge]
GO
/****** Object:  Table [dbo].[TB_VendorReferenceDetails]    Script Date: 5/2/2020 6:44:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_VendorReferenceDetails](
	[ReferenceID] [int] IDENTITY(1,1) NOT NULL,
	[Account] [varchar](100) NOT NULL,
	[ReferenceNo] [varchar](100) NOT NULL,
	[Accountid] [int] NOT NULL,
	[VendorSourceid] [int] NULL,
	[OfferTemplateID] [int] NULL,
	[VendorValueSourceid] [int] NULL,
	[MultipleSheetsInOffer] [int] NOT NULL,
	[ParseTemplateName] [varchar](200) NOT NULL,
	[AutoOfferUploadFlag] [int] NOT NULL,
	[SkipRateIncreaseCheck] [int] NOT NULL,
	[EnableEmailCheck] [tinyint] NOT NULL,
	[RateIncreasePeriod] [int] NULL,
	[ModifiedDate] [datetime] NULL,
	[ModifiedByID] [int] NULL,
	[CheckNewDestination] [int] NULL,
 CONSTRAINT [PK_VendorReferenceDetails] PRIMARY KEY CLUSTERED 
(
	[ReferenceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [uc_ReferenceNo] UNIQUE NONCLUSTERED 
(
	[ReferenceNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
