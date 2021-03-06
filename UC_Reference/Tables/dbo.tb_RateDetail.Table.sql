USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_RateDetail]    Script Date: 5/2/2020 6:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_RateDetail](
	[RateDetailID] [int] IDENTITY(1,1) NOT NULL,
	[Rate] [decimal](19, 6) NOT NULL,
	[RateID] [int] NOT NULL,
	[RateTypeID] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_RateDetail] PRIMARY KEY CLUSTERED 
(
	[RateDetailID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_RateDetail] UNIQUE NONCLUSTERED 
(
	[RateID] ASC,
	[RateTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_RateDetail] ADD  CONSTRAINT [DF_tb_RateDetail_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_RateDetail] ADD  CONSTRAINT [DF_tb_RateDetail_ModifiedByID]  DEFAULT ((1)) FOR [ModifiedByID]
GO
ALTER TABLE [dbo].[tb_RateDetail] ADD  CONSTRAINT [DF_tb_RateDetail_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_RateDetail]  WITH CHECK ADD  CONSTRAINT [FK_tb_RateDetail_tb_Rate] FOREIGN KEY([RateID])
REFERENCES [dbo].[tb_Rate] ([RateID])
GO
ALTER TABLE [dbo].[tb_RateDetail] CHECK CONSTRAINT [FK_tb_RateDetail_tb_Rate]
GO
ALTER TABLE [dbo].[tb_RateDetail]  WITH CHECK ADD  CONSTRAINT [FK_tb_RateDetail_tb_RateItem] FOREIGN KEY([RateTypeID])
REFERENCES [dbo].[tb_RateItem] ([RateItemID])
GO
ALTER TABLE [dbo].[tb_RateDetail] CHECK CONSTRAINT [FK_tb_RateDetail_tb_RateItem]
GO
