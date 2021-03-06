USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_RateStructureRateItem]    Script Date: 5/2/2020 6:27:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_RateStructureRateItem](
	[RateStructureItemID] [int] IDENTITY(1,1) NOT NULL,
	[RateStructureID] [int] NOT NULL,
	[Number] [int] NOT NULL,
	[RateItemID] [int] NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [tb_RateStructureItem_PK] PRIMARY KEY CLUSTERED 
(
	[RateStructureItemID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_RateStructureRateItem] ADD  CONSTRAINT [DF__tb_RateStructureItem__ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_RateStructureRateItem] ADD  CONSTRAINT [DF__tb_RateStructureItem__ModifiedByID]  DEFAULT ((-1)) FOR [ModifiedByID]
GO
ALTER TABLE [dbo].[tb_RateStructureRateItem] ADD  CONSTRAINT [DF__tb_RateStructureItem__Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_RateStructureRateItem]  WITH CHECK ADD  CONSTRAINT [FK_tb_RateStructure_tb_RateStructureItem] FOREIGN KEY([RateStructureID])
REFERENCES [dbo].[tb_RateStructure] ([RateStructureID])
GO
ALTER TABLE [dbo].[tb_RateStructureRateItem] CHECK CONSTRAINT [FK_tb_RateStructure_tb_RateStructureItem]
GO
ALTER TABLE [dbo].[tb_RateStructureRateItem]  WITH CHECK ADD  CONSTRAINT [FK_tb_RateStructureItem_tbRateItem] FOREIGN KEY([RateItemID])
REFERENCES [dbo].[tb_RateItem] ([RateItemID])
GO
ALTER TABLE [dbo].[tb_RateStructureRateItem] CHECK CONSTRAINT [FK_tb_RateStructureItem_tbRateItem]
GO
