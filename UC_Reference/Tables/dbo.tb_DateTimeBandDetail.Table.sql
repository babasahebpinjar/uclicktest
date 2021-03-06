USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_DateTimeBandDetail]    Script Date: 5/2/2020 6:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_DateTimeBandDetail](
	[DateTimeBandDetailID] [int] IDENTITY(1,1) NOT NULL,
	[DateTimeBandID] [int] NOT NULL,
	[EventYear] [int] NOT NULL,
	[EventMonth] [int] NOT NULL,
	[EventDay] [int] NOT NULL,
	[EventWeekDay] [int] NOT NULL,
	[FromField] [int] NOT NULL,
	[ToField] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tbDateTimeZoneDetail] PRIMARY KEY CLUSTERED 
(
	[DateTimeBandDetailID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_DateTimeBandDetail]  WITH CHECK ADD  CONSTRAINT [FK_tb_DateTimeBandDetail_tb_RateDimensionBand] FOREIGN KEY([DateTimeBandID])
REFERENCES [dbo].[tb_RateDimensionBand] ([RateDimensionBandID])
GO
ALTER TABLE [dbo].[tb_DateTimeBandDetail] CHECK CONSTRAINT [FK_tb_DateTimeBandDetail_tb_RateDimensionBand]
GO
