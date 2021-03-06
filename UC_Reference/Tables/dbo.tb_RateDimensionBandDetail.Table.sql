USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_RateDimensionBandDetail]    Script Date: 5/2/2020 6:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_RateDimensionBandDetail](
	[RateDimensionBandDetailID] [int] IDENTITY(1,1) NOT NULL,
	[RateDimensionBandID] [int] NOT NULL,
	[FromField] [varchar](30) NOT NULL,
	[ToField] [varchar](30) NULL,
	[ApplyFrom] [int] NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tbRateDimensionBandDetail] PRIMARY KEY CLUSTERED 
(
	[RateDimensionBandDetailID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_RateDimensionBandDetail]  WITH CHECK ADD  CONSTRAINT [FK_tbRateDimensionBandDetail_tbRateDimensionBand] FOREIGN KEY([RateDimensionBandID])
REFERENCES [dbo].[tb_RateDimensionBand] ([RateDimensionBandID])
GO
ALTER TABLE [dbo].[tb_RateDimensionBandDetail] CHECK CONSTRAINT [FK_tbRateDimensionBandDetail_tbRateDimensionBand]
GO
