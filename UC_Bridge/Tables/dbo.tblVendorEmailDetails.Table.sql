USE [UC_Bridge]
GO
/****** Object:  Table [dbo].[tblVendorEmailDetails]    Script Date: 5/2/2020 6:44:28 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblVendorEmailDetails](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ReferenceID] [int] NOT NULL,
	[OfferTypeID] [int] NOT NULL,
	[EmailAddress] [nvarchar](150) NOT NULL,
	[Subject] [nvarchar](500) NOT NULL,
	[CreatedDate] [datetime] NULL,
	[UpdatedDate] [datetime] NULL,
 CONSTRAINT [PK_tblVendorEmailDetails] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [uc_Email_Reference_OfferType_Subject] UNIQUE NONCLUSTERED 
(
	[EmailAddress] ASC,
	[ReferenceID] ASC,
	[OfferTypeID] ASC,
	[Subject] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
