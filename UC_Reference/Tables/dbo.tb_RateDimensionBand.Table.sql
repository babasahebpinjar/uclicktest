USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_RateDimensionBand]    Script Date: 5/2/2020 6:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_RateDimensionBand](
	[RateDimensionBandID] [int] IDENTITY(1,1) NOT NULL,
	[RateDimensionBand] [varchar](100) NOT NULL,
	[RateDimensionBandAbbrv] [varchar](60) NULL,
	[RateDimensionTemplateID] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_RateDimensionBand] PRIMARY KEY CLUSTERED 
(
	[RateDimensionBandID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_RateDimensionBand]  WITH CHECK ADD  CONSTRAINT [FK_tb_RateDimensionBand_tb_RateDimensionTemplate] FOREIGN KEY([RateDimensionTemplateID])
REFERENCES [dbo].[tb_RateDimensionTemplate] ([RateDimensionTemplateID])
GO
ALTER TABLE [dbo].[tb_RateDimensionBand] CHECK CONSTRAINT [FK_tb_RateDimensionBand_tb_RateDimensionTemplate]
GO
