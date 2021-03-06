USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_RatingMethodDetail]    Script Date: 5/2/2020 6:27:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_RatingMethodDetail](
	[RatingMethodDetailID] [int] IDENTITY(1,1) NOT NULL,
	[RatingMethodID] [int] NOT NULL,
	[Number] [int] NOT NULL,
	[ItemValue] [decimal](19, 6) NULL,
	[RateItemID] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_RatingMethodDetail] PRIMARY KEY CLUSTERED 
(
	[RatingMethodDetailID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_RatingMethodDetail] UNIQUE NONCLUSTERED 
(
	[RatingMethodID] ASC,
	[RateItemID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_RatingMethodDetail] ADD  CONSTRAINT [DF__tb_RatingMethodAttribute__ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_RatingMethodDetail] ADD  CONSTRAINT [DF__tb_RatingMethodAttribute__ModifiedByID]  DEFAULT ((-1)) FOR [ModifiedByID]
GO
ALTER TABLE [dbo].[tb_RatingMethodDetail] ADD  CONSTRAINT [DF__tb_RatingMethodAttribute__Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_RatingMethodDetail]  WITH CHECK ADD  CONSTRAINT [FK_tb_RatingMethodDetail_tb_RateItem] FOREIGN KEY([RateItemID])
REFERENCES [dbo].[tb_RateItem] ([RateItemID])
GO
ALTER TABLE [dbo].[tb_RatingMethodDetail] CHECK CONSTRAINT [FK_tb_RatingMethodDetail_tb_RateItem]
GO
ALTER TABLE [dbo].[tb_RatingMethodDetail]  WITH CHECK ADD  CONSTRAINT [FK_tb_RatingMethodDetail_tb_RatingMethod] FOREIGN KEY([RatingMethodID])
REFERENCES [dbo].[tb_RatingMethod] ([RatingMethodID])
GO
ALTER TABLE [dbo].[tb_RatingMethodDetail] CHECK CONSTRAINT [FK_tb_RatingMethodDetail_tb_RatingMethod]
GO
