USE [UC_Commerce]
GO
/****** Object:  Table [dbo].[tb_UploadDestination]    Script Date: 5/2/2020 6:14:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_UploadDestination](
	[UploadDestinationID] [int] IDENTITY(1,1) NOT NULL,
	[OfferID] [int] NOT NULL,
	[SourceID] [int] NOT NULL,
	[OfferDate] [datetime] NOT NULL,
	[Destination] [varchar](60) NOT NULL,
	[DestinationID] [int] NULL,
	[EffectiveDate] [datetime] NOT NULL,
	[RatingMethodID] [int] NOT NULL,
	[DestinationTypeID] [int] NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_UploadDestination] PRIMARY KEY CLUSTERED 
(
	[UploadDestinationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_UploadDestination] ADD  CONSTRAINT [DF_tbUploadDest_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_UploadDestination] ADD  CONSTRAINT [DF_tbUploadDest_Flag]  DEFAULT ((0)) FOR [Flag]
GO
