USE [UC_Bridge]
GO
/****** Object:  Table [dbo].[TB_VendorOfferDetails]    Script Date: 5/2/2020 6:44:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TB_VendorOfferDetails](
	[VendorOfferID] [int] IDENTITY(1,1) NOT NULL,
	[Referenceid] [int] NOT NULL,
	[OfferFileName] [varchar](500) NOT NULL,
	[LoadOfferName] [varchar](500) NULL,
	[OfferReceiveDate] [datetime] NOT NULL,
	[OfferType] [varchar](20) NOT NULL,
	[OfferTypeID] [int] NOT NULL,
	[OfferProcessDate] [datetime] NULL,
	[OfferStatus] [varchar](100) NOT NULL,
	[OfferStatusID] [int] NOT NULL,
	[AcknowledgementSend] [varchar](10) NOT NULL,
	[ProcessedStatusSend] [varchar](10) NOT NULL,
	[UploadOfferType] [varchar](20) NULL,
	[UploadOfferTypeID] [int] NULL,
	[PartialOfferProcessFlag] [int] NULL,
	[RandomIDValue] [varchar](100) NULL,
	[ValidatedOfferFileName] [varchar](500) NULL,
	[ModifiedDate] [datetime] NULL,
	[ModifiedByID] [int] NULL,
 CONSTRAINT [PK_TB_VendorOfferDetails] PRIMARY KEY CLUSTERED 
(
	[VendorOfferID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [uc_Ref_OffrTyp_OffrSts_OffrDt] UNIQUE NONCLUSTERED 
(
	[Referenceid] ASC,
	[OfferFileName] ASC,
	[OfferTypeID] ASC,
	[OfferReceiveDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
