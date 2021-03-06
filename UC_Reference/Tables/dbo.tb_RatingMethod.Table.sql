USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_RatingMethod]    Script Date: 5/2/2020 6:27:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_RatingMethod](
	[RatingMethodID] [int] IDENTITY(1,1) NOT NULL,
	[RatingMethod] [varchar](100) NOT NULL,
	[RatingMethodAbbrv] [varchar](60) NOT NULL,
	[RateStructureID] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_RatingMethod] PRIMARY KEY CLUSTERED 
(
	[RatingMethodID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_RatingMethod] ADD  CONSTRAINT [DF__tb_RatingMethod__ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_RatingMethod] ADD  CONSTRAINT [DF__tb_RatingMethod__ModifiedByID]  DEFAULT ((-1)) FOR [ModifiedByID]
GO
ALTER TABLE [dbo].[tb_RatingMethod] ADD  CONSTRAINT [DF__tb_RatingMethod__Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_RatingMethod]  WITH CHECK ADD  CONSTRAINT [FK_tb_RatingMethod_tb_RateStructure] FOREIGN KEY([RateStructureID])
REFERENCES [dbo].[tb_RateStructure] ([RateStructureID])
GO
ALTER TABLE [dbo].[tb_RatingMethod] CHECK CONSTRAINT [FK_tb_RatingMethod_tb_RateStructure]
GO
