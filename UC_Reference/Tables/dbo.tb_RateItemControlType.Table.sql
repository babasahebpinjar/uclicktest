USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_RateItemControlType]    Script Date: 5/2/2020 6:27:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_RateItemControlType](
	[RateItemControlTypeID] [int] IDENTITY(1,1) NOT NULL,
	[RateItemID] [int] NOT NULL,
	[UIControlTypeID] [int] NOT NULL,
	[ExecutionScript] [varchar](1000) NULL,
	[ParamCount] [int] NULL,
	[Param1] [varchar](100) NULL,
	[Param2] [varchar](100) NULL,
	[Param3] [varchar](100) NULL,
	[Param4] [varchar](100) NULL,
	[Param5] [varchar](100) NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_RateItemControlType] PRIMARY KEY CLUSTERED 
(
	[RateItemControlTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_RateItemControlType] UNIQUE NONCLUSTERED 
(
	[RateItemID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_RateItemControlType] ADD  CONSTRAINT [DF_tb_RateItemControlType_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_RateItemControlType] ADD  CONSTRAINT [DF_tb_RateItemControlType_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_RateItemControlType]  WITH CHECK ADD  CONSTRAINT [FK_tb_RateItemControlType_tb_RateItem] FOREIGN KEY([RateItemID])
REFERENCES [dbo].[tb_RateItem] ([RateItemID])
GO
ALTER TABLE [dbo].[tb_RateItemControlType] CHECK CONSTRAINT [FK_tb_RateItemControlType_tb_RateItem]
GO
ALTER TABLE [dbo].[tb_RateItemControlType]  WITH CHECK ADD  CONSTRAINT [FK_tb_RateItemControlType_tb_UIControlType] FOREIGN KEY([UIControlTypeID])
REFERENCES [dbo].[tb_UIControlType] ([UIControlTypeID])
GO
ALTER TABLE [dbo].[tb_RateItemControlType] CHECK CONSTRAINT [FK_tb_RateItemControlType_tb_UIControlType]
GO
