USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_TrunkDetail]    Script Date: 5/2/2020 6:27:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_TrunkDetail](
	[TrunKDetailID] [int] IDENTITY(1,1) NOT NULL,
	[EffectiveDate] [datetime] NOT NULL,
	[ActivatedPorts] [int] NULL,
	[AvailablePorts] [int] NULL,
	[ProcessCode] [char](1) NULL,
	[TargetUsage] [int] NULL,
	[TrunkID] [int] NOT NULL,
	[ActiveStatusID] [int] NOT NULL,
	[CommercialTrunkID] [int] NULL,
	[DirectionID] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_TrunkDetail] PRIMARY KEY CLUSTERED 
(
	[TrunKDetailID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_TrunkDetail] UNIQUE NONCLUSTERED 
(
	[TrunkID] ASC,
	[EffectiveDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_TrunkDetail] ADD  CONSTRAINT [DF_tb_TrunkDetail_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_TrunkDetail] ADD  CONSTRAINT [DF_tb_TrunkDetail_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_TrunkDetail]  WITH CHECK ADD  CONSTRAINT [FK_tb_TrunkDetail_tb_ActiveStatus] FOREIGN KEY([ActiveStatusID])
REFERENCES [dbo].[tb_ActiveStatus] ([ActiveStatusID])
GO
ALTER TABLE [dbo].[tb_TrunkDetail] CHECK CONSTRAINT [FK_tb_TrunkDetail_tb_ActiveStatus]
GO
ALTER TABLE [dbo].[tb_TrunkDetail]  WITH CHECK ADD  CONSTRAINT [FK_tb_TrunkDetail_tb_Trunk] FOREIGN KEY([TrunkID])
REFERENCES [dbo].[tb_Trunk] ([TrunkID])
GO
ALTER TABLE [dbo].[tb_TrunkDetail] CHECK CONSTRAINT [FK_tb_TrunkDetail_tb_Trunk]
GO
