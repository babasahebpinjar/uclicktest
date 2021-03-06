USE [UC_Bridge]
GO
/****** Object:  Table [dbo].[tb_OfferStatusWorkflow]    Script Date: 5/2/2020 6:44:26 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_OfferStatusWorkflow](
	[OfferStatusWorkflowID] [int] IDENTITY(1,1) NOT NULL,
	[FromVendorOfferStatusID] [int] NOT NULL,
	[ToVendorOfferStatusID] [int] NOT NULL,
	[TransitionFlag] [int] NOT NULL,
 CONSTRAINT [PK_OfferStatusWorkflowID] PRIMARY KEY CLUSTERED 
(
	[OfferStatusWorkflowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [uc_FromVendorOfferStatusID_ToVendorOfferStatusID] UNIQUE NONCLUSTERED 
(
	[FromVendorOfferStatusID] ASC,
	[ToVendorOfferStatusID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
