USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_RateDimensionTemplate]    Script Date: 5/2/2020 6:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_RateDimensionTemplate](
	[RateDimensionTemplateID] [int] IDENTITY(1,1) NOT NULL,
	[RateDimensionTemplate] [varchar](100) NOT NULL,
	[RateDimensionID] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_RateDimensionTemplate] PRIMARY KEY CLUSTERED 
(
	[RateDimensionTemplateID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_RateDimensionTemplate]  WITH CHECK ADD  CONSTRAINT [FK_tb_RateDimensionTemplate_tb_RateDimension] FOREIGN KEY([RateDimensionID])
REFERENCES [dbo].[tb_RateDimension] ([RateDimensionID])
GO
ALTER TABLE [dbo].[tb_RateDimensionTemplate] CHECK CONSTRAINT [FK_tb_RateDimensionTemplate_tb_RateDimension]
GO
