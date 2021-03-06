USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_RateItemType]    Script Date: 5/2/2020 6:27:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_RateItemType](
	[RateItemTypeID] [int] IDENTITY(1,1) NOT NULL,
	[RateItemType] [varchar](60) NOT NULL,
	[RateItemDescription] [varchar](255) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [tbItemType_PK] PRIMARY KEY CLUSTERED 
(
	[RateItemTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_RateItemType] ADD  CONSTRAINT [DF__tbItemType__ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_RateItemType] ADD  CONSTRAINT [DF__tbItemType__ModifiedByID]  DEFAULT ((-1)) FOR [ModifiedByID]
GO
ALTER TABLE [dbo].[tb_RateItemType] ADD  CONSTRAINT [DF__tbItemType__Flag]  DEFAULT ((0)) FOR [Flag]
GO
