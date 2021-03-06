USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_Trunk]    Script Date: 5/2/2020 6:27:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_Trunk](
	[TrunkID] [int] IDENTITY(1,1) NOT NULL,
	[Trunk] [varchar](60) NOT NULL,
	[CLLI] [varchar](30) NULL,
	[OrigPointCode] [varchar](30) NULL,
	[PointCode] [varchar](30) NULL,
	[ReportCode] [varchar](30) NULL,
	[Description] [varchar](255) NULL,
	[Note] [nvarchar](4000) NULL,
	[CDRMatch] [varchar](30) NOT NULL,
	[TrunkIPAddress] [varchar](30) NULL,
	[TimeZoneShiftMinutes] [int] NULL,
	[TrunkTypeID] [int] NOT NULL,
	[SwitchID] [int] NOT NULL,
	[TSwitchID] [int] NULL,
	[AccountID] [int] NOT NULL,
	[TransmissionTypeID] [int] NULL,
	[SignalingTypeID] [int] NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_Trunk] PRIMARY KEY CLUSTERED 
(
	[TrunkID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_Trunk]  WITH CHECK ADD  CONSTRAINT [FK_tb_Trunk_tb_Account] FOREIGN KEY([AccountID])
REFERENCES [dbo].[tb_Account] ([AccountID])
GO
ALTER TABLE [dbo].[tb_Trunk] CHECK CONSTRAINT [FK_tb_Trunk_tb_Account]
GO
ALTER TABLE [dbo].[tb_Trunk]  WITH CHECK ADD  CONSTRAINT [FK_tb_Trunk_tb_SignalingType] FOREIGN KEY([SignalingTypeID])
REFERENCES [dbo].[tb_SignalingType] ([SignalingTypeID])
GO
ALTER TABLE [dbo].[tb_Trunk] CHECK CONSTRAINT [FK_tb_Trunk_tb_SignalingType]
GO
ALTER TABLE [dbo].[tb_Trunk]  WITH CHECK ADD  CONSTRAINT [FK_tb_Trunk_tb_Switch] FOREIGN KEY([SwitchID])
REFERENCES [dbo].[tb_Switch] ([SwitchID])
GO
ALTER TABLE [dbo].[tb_Trunk] CHECK CONSTRAINT [FK_tb_Trunk_tb_Switch]
GO
ALTER TABLE [dbo].[tb_Trunk]  WITH CHECK ADD  CONSTRAINT [FK_tb_Trunk_tb_TransmissionType] FOREIGN KEY([TransmissionTypeID])
REFERENCES [dbo].[tb_TransmissionType] ([TransmissionTypeID])
GO
ALTER TABLE [dbo].[tb_Trunk] CHECK CONSTRAINT [FK_tb_Trunk_tb_TransmissionType]
GO
ALTER TABLE [dbo].[tb_Trunk]  WITH CHECK ADD  CONSTRAINT [FK_tb_Trunk_tb_TrunkType] FOREIGN KEY([TrunkTypeID])
REFERENCES [dbo].[tb_TrunkType] ([TrunkTypeID])
GO
ALTER TABLE [dbo].[tb_Trunk] CHECK CONSTRAINT [FK_tb_Trunk_tb_TrunkType]
GO
