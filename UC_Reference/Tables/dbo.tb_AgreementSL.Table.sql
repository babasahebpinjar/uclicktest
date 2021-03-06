USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_AgreementSL]    Script Date: 5/2/2020 6:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_AgreementSL](
	[AgreementSLID] [int] IDENTITY(1,1) NOT NULL,
	[AgreementID] [int] NOT NULL,
	[TrunkID] [int] NOT NULL,
	[DirectionID] [int] NOT NULL,
	[DestinationID] [int] NULL,
	[ServiceLevelID] [int] NOT NULL,
	[BeginDate] [datetime] NOT NULL,
	[EndDate] [datetime] NULL,
	[CallingNumber] [varchar](15) NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_AgreementRC] PRIMARY KEY CLUSTERED 
(
	[AgreementSLID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_AgreementSL] ADD  CONSTRAINT [DF_tb_AgreementSL_CallingNumber]  DEFAULT (NULL) FOR [CallingNumber]
GO
ALTER TABLE [dbo].[tb_AgreementSL] ADD  CONSTRAINT [DF_tb_AgreementSL_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_AgreementSL] ADD  CONSTRAINT [DF_tb_AgreementSL_ModifiedByID]  DEFAULT ((1)) FOR [ModifiedByID]
GO
ALTER TABLE [dbo].[tb_AgreementSL] ADD  CONSTRAINT [DF_tb_AgreementSL_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_AgreementSL]  WITH CHECK ADD  CONSTRAINT [FK_tb_AgreementSL_tb_Agreement] FOREIGN KEY([AgreementID])
REFERENCES [dbo].[tb_Agreement] ([AgreementID])
GO
ALTER TABLE [dbo].[tb_AgreementSL] CHECK CONSTRAINT [FK_tb_AgreementSL_tb_Agreement]
GO
ALTER TABLE [dbo].[tb_AgreementSL]  WITH CHECK ADD  CONSTRAINT [FK_tb_AgreementSL_tb_Direction] FOREIGN KEY([DirectionID])
REFERENCES [dbo].[tb_Direction] ([DirectionID])
GO
ALTER TABLE [dbo].[tb_AgreementSL] CHECK CONSTRAINT [FK_tb_AgreementSL_tb_Direction]
GO
ALTER TABLE [dbo].[tb_AgreementSL]  WITH CHECK ADD  CONSTRAINT [FK_tb_AgreementSL_tb_ServiceLevel] FOREIGN KEY([ServiceLevelID])
REFERENCES [dbo].[tb_ServiceLevel] ([ServiceLevelID])
GO
ALTER TABLE [dbo].[tb_AgreementSL] CHECK CONSTRAINT [FK_tb_AgreementSL_tb_ServiceLevel]
GO
ALTER TABLE [dbo].[tb_AgreementSL]  WITH CHECK ADD  CONSTRAINT [FK_tb_AgreementSL_tb_Trunk] FOREIGN KEY([TrunkID])
REFERENCES [dbo].[tb_Trunk] ([TrunkID])
GO
ALTER TABLE [dbo].[tb_AgreementSL] CHECK CONSTRAINT [FK_tb_AgreementSL_tb_Trunk]
GO
