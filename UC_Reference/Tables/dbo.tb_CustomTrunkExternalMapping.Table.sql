USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_CustomTrunkExternalMapping]    Script Date: 5/2/2020 6:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_CustomTrunkExternalMapping](
	[CustomTrunkExternalMappingID] [int] IDENTITY(1,1) NOT NULL,
	[TrunkID] [int] NOT NULL,
	[VirtualNetwork] [varchar](10) NOT NULL,
	[TrunkGroup] [varchar](10) NOT NULL,
	[RouteProfileID] [int] NOT NULL,
	[LinkStatus] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
 CONSTRAINT [PK_tb_CustomTrunkExternalMapping] PRIMARY KEY CLUSTERED 
(
	[CustomTrunkExternalMappingID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_CustomTrunkExternalMapping] UNIQUE NONCLUSTERED 
(
	[TrunkID] ASC,
	[VirtualNetwork] ASC,
	[TrunkGroup] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_CustomTrunkExternalMapping]  WITH CHECK ADD  CONSTRAINT [FK_tb_CustomTrunkExternalMapping_tb_Trunk] FOREIGN KEY([TrunkID])
REFERENCES [dbo].[tb_Trunk] ([TrunkID])
GO
ALTER TABLE [dbo].[tb_CustomTrunkExternalMapping] CHECK CONSTRAINT [FK_tb_CustomTrunkExternalMapping_tb_Trunk]
GO
ALTER TABLE [dbo].[tb_CustomTrunkExternalMapping]  WITH CHECK ADD  CONSTRAINT [CHK_LinkStatus_tb_CustomTrunkExternalMapping] CHECK  (([LinkStatus]=(2) OR [LinkStatus]=(1) OR [LinkStatus]=(0)))
GO
ALTER TABLE [dbo].[tb_CustomTrunkExternalMapping] CHECK CONSTRAINT [CHK_LinkStatus_tb_CustomTrunkExternalMapping]
GO
