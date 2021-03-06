USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_RateItem]    Script Date: 5/2/2020 6:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_RateItem](
	[RateItemID] [int] NOT NULL,
	[RateItemName] [varchar](100) NOT NULL,
	[RateItemAbbrv] [varchar](60) NOT NULL,
	[RateItemDescription] [varchar](255) NOT NULL,
	[RateItemTypeID] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tbItem] PRIMARY KEY CLUSTERED 
(
	[RateItemID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_RateItem] ADD  CONSTRAINT [DF_tbItem_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_RateItem] ADD  CONSTRAINT [DF_tbItem_ModifiedByID]  DEFAULT ((-1)) FOR [ModifiedByID]
GO
ALTER TABLE [dbo].[tb_RateItem] ADD  CONSTRAINT [DF_tbItem_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_RateItem]  WITH CHECK ADD  CONSTRAINT [FK_tbRateItem_tbRateItemType] FOREIGN KEY([RateItemTypeID])
REFERENCES [dbo].[tb_RateItemType] ([RateItemTypeID])
GO
ALTER TABLE [dbo].[tb_RateItem] CHECK CONSTRAINT [FK_tbRateItem_tbRateItemType]
GO
