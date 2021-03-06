USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_CDRProcessingRule]    Script Date: 5/2/2020 6:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_CDRProcessingRule](
	[CDRProcessingRuleID] [int] IDENTITY(1,1) NOT NULL,
	[RuleOrder] [int] NOT NULL,
	[PrefixCode] [varchar](100) NULL,
	[TrunkID] [int] NOT NULL,
	[ServiceLevelID] [int] NOT NULL,
	[DirectionID] [int] NOT NULL,
	[BeginDate] [datetime] NOT NULL,
	[EndDate] [datetime] NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
 CONSTRAINT [PK_tb_CDRProcessingRule] PRIMARY KEY CLUSTERED 
(
	[CDRProcessingRuleID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_CDRProcessingRule] ADD  CONSTRAINT [DF_tb_CDRProcessingRule_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_CDRProcessingRule]  WITH CHECK ADD  CONSTRAINT [FK_tb_CDRProcessingRule_tb_Direction] FOREIGN KEY([DirectionID])
REFERENCES [dbo].[tb_Direction] ([DirectionID])
GO
ALTER TABLE [dbo].[tb_CDRProcessingRule] CHECK CONSTRAINT [FK_tb_CDRProcessingRule_tb_Direction]
GO
ALTER TABLE [dbo].[tb_CDRProcessingRule]  WITH CHECK ADD  CONSTRAINT [FK_tb_CDRProcessingRule_tb_ServiceLevel] FOREIGN KEY([ServiceLevelID])
REFERENCES [dbo].[tb_ServiceLevel] ([ServiceLevelID])
GO
ALTER TABLE [dbo].[tb_CDRProcessingRule] CHECK CONSTRAINT [FK_tb_CDRProcessingRule_tb_ServiceLevel]
GO
ALTER TABLE [dbo].[tb_CDRProcessingRule]  WITH CHECK ADD  CONSTRAINT [FK_tb_CDRProcessingRule_tb_Trunk] FOREIGN KEY([TrunkID])
REFERENCES [dbo].[tb_Trunk] ([TrunkID])
GO
ALTER TABLE [dbo].[tb_CDRProcessingRule] CHECK CONSTRAINT [FK_tb_CDRProcessingRule_tb_Trunk]
GO
