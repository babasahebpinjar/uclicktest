USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_Switch]    Script Date: 5/2/2020 6:27:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_Switch](
	[SwitchID] [int] IDENTITY(1,1) NOT NULL,
	[Switch] [varchar](30) NOT NULL,
	[SwitchAbbrv] [varchar](10) NOT NULL,
	[CLLI] [varchar](30) NULL,
	[SwitchTypeID] [int] NOT NULL,
	[ExternalCode] [varchar](25) NULL,
	[UseForLCR] [int] NOT NULL,
	[UseForRG] [int] NOT NULL,
	[UseForCostAllocation] [int] NOT NULL,
	[UseForRatePlan] [int] NOT NULL,
	[UseForTrafficAnalysis] [int] NOT NULL,
	[TimeZoneShiftMinutes] [int] NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_Switch] PRIMARY KEY CLUSTERED 
(
	[SwitchID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_Switch] ADD  CONSTRAINT [DF_tb_Switch_UseForLCR]  DEFAULT ((0)) FOR [UseForLCR]
GO
ALTER TABLE [dbo].[tb_Switch] ADD  CONSTRAINT [DF_tb_Switch_UseForRG]  DEFAULT ((0)) FOR [UseForRG]
GO
ALTER TABLE [dbo].[tb_Switch] ADD  CONSTRAINT [DF_tb_Switch_UseForCostAllocation]  DEFAULT ((0)) FOR [UseForCostAllocation]
GO
ALTER TABLE [dbo].[tb_Switch] ADD  CONSTRAINT [DF_tb_Switch_UseForRatePlan]  DEFAULT ((0)) FOR [UseForRatePlan]
GO
ALTER TABLE [dbo].[tb_Switch] ADD  CONSTRAINT [DF_tb_Switch_UseForRatePlan1]  DEFAULT ((0)) FOR [UseForTrafficAnalysis]
GO
ALTER TABLE [dbo].[tb_Switch] ADD  CONSTRAINT [DF_tb_Switch_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_Switch] ADD  CONSTRAINT [DF_tb_Switch_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_Switch]  WITH CHECK ADD  CONSTRAINT [FK_tb_Switch_tb_SwitchType] FOREIGN KEY([SwitchTypeID])
REFERENCES [dbo].[tb_SwitchType] ([SwitchTypeID])
GO
ALTER TABLE [dbo].[tb_Switch] CHECK CONSTRAINT [FK_tb_Switch_tb_SwitchType]
GO
ALTER TABLE [dbo].[tb_Switch]  WITH NOCHECK ADD  CONSTRAINT [CK_tb_Switch] CHECK  (([UseForLCR]>=(0) AND [UseForLCR]<=(1) AND ([UseForCostAllocation]>=(0) AND [UseForCostAllocation]<=(1)) AND ([UseForRG]>=(0) AND [UseForRG]<=(1)) AND ([UseForRatePlan]>=(0) AND [UseForRatePlan]<=(1)) AND ([UseForTrafficAnalysis]>=(0) AND [UseForTrafficAnalysis]<=(1))))
GO
ALTER TABLE [dbo].[tb_Switch] CHECK CONSTRAINT [CK_tb_Switch]
GO
