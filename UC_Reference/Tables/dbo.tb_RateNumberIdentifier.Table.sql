USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_RateNumberIdentifier]    Script Date: 5/2/2020 6:27:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_RateNumberIdentifier](
	[RateNumberIdentifierID] [int] IDENTITY(1,1) NOT NULL,
	[RateDimension1BandID] [int] NULL,
	[RateDimension2BandID] [int] NULL,
	[RateDimension3BandID] [int] NULL,
	[RateDimension4BandID] [int] NULL,
	[RateDimension5BandID] [int] NULL,
	[RatingMethodID] [int] NOT NULL,
	[RateItemID] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_RateNumberIdentifier] PRIMARY KEY CLUSTERED 
(
	[RateNumberIdentifierID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_RateNumberIdentifier]  WITH CHECK ADD  CONSTRAINT [FK_tb_RateNumberIdentifier_tb_RateDimensionBand] FOREIGN KEY([RateDimension1BandID])
REFERENCES [dbo].[tb_RateDimensionBand] ([RateDimensionBandID])
GO
ALTER TABLE [dbo].[tb_RateNumberIdentifier] CHECK CONSTRAINT [FK_tb_RateNumberIdentifier_tb_RateDimensionBand]
GO
ALTER TABLE [dbo].[tb_RateNumberIdentifier]  WITH CHECK ADD  CONSTRAINT [FK_tb_RateNumberIdentifier_tb_RateDimensionBand1] FOREIGN KEY([RateDimension2BandID])
REFERENCES [dbo].[tb_RateDimensionBand] ([RateDimensionBandID])
GO
ALTER TABLE [dbo].[tb_RateNumberIdentifier] CHECK CONSTRAINT [FK_tb_RateNumberIdentifier_tb_RateDimensionBand1]
GO
ALTER TABLE [dbo].[tb_RateNumberIdentifier]  WITH CHECK ADD  CONSTRAINT [FK_tb_RateNumberIdentifier_tb_RateDimensionBand2] FOREIGN KEY([RateDimension3BandID])
REFERENCES [dbo].[tb_RateDimensionBand] ([RateDimensionBandID])
GO
ALTER TABLE [dbo].[tb_RateNumberIdentifier] CHECK CONSTRAINT [FK_tb_RateNumberIdentifier_tb_RateDimensionBand2]
GO
ALTER TABLE [dbo].[tb_RateNumberIdentifier]  WITH CHECK ADD  CONSTRAINT [FK_tb_RateNumberIdentifier_tb_RateDimensionBand3] FOREIGN KEY([RateDimension4BandID])
REFERENCES [dbo].[tb_RateDimensionBand] ([RateDimensionBandID])
GO
ALTER TABLE [dbo].[tb_RateNumberIdentifier] CHECK CONSTRAINT [FK_tb_RateNumberIdentifier_tb_RateDimensionBand3]
GO
ALTER TABLE [dbo].[tb_RateNumberIdentifier]  WITH CHECK ADD  CONSTRAINT [FK_tb_RateNumberIdentifier_tb_RateDimensionBand4] FOREIGN KEY([RateDimension5BandID])
REFERENCES [dbo].[tb_RateDimensionBand] ([RateDimensionBandID])
GO
ALTER TABLE [dbo].[tb_RateNumberIdentifier] CHECK CONSTRAINT [FK_tb_RateNumberIdentifier_tb_RateDimensionBand4]
GO
ALTER TABLE [dbo].[tb_RateNumberIdentifier]  WITH CHECK ADD  CONSTRAINT [FK_tb_RateNumberIdentifier_tb_RateItem] FOREIGN KEY([RateItemID])
REFERENCES [dbo].[tb_RateItem] ([RateItemID])
GO
ALTER TABLE [dbo].[tb_RateNumberIdentifier] CHECK CONSTRAINT [FK_tb_RateNumberIdentifier_tb_RateItem]
GO
ALTER TABLE [dbo].[tb_RateNumberIdentifier]  WITH CHECK ADD  CONSTRAINT [FK_tb_RateNumberIdentifier_tb_RatingMethod] FOREIGN KEY([RatingMethodID])
REFERENCES [dbo].[tb_RatingMethod] ([RatingMethodID])
GO
ALTER TABLE [dbo].[tb_RateNumberIdentifier] CHECK CONSTRAINT [FK_tb_RateNumberIdentifier_tb_RatingMethod]
GO
