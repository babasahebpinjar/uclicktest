USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_NumberPlan]    Script Date: 5/2/2020 6:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_NumberPlan](
	[NumberPlanID] [int] IDENTITY(1,1) NOT NULL,
	[NumberPlan] [varchar](100) NOT NULL,
	[NumberPlanAbbrv] [varchar](60) NOT NULL,
	[ExternalCode] [varchar](25) NULL,
	[NumberPlanTypeID] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_NumberPlan] PRIMARY KEY CLUSTERED 
(
	[NumberPlanID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_NumberPlan] UNIQUE NONCLUSTERED 
(
	[NumberPlan] ASC,
	[NumberPlanAbbrv] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_NumberPlan] ADD  CONSTRAINT [DF_tb_NumberPlan_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_NumberPlan] ADD  CONSTRAINT [DF_tb_NumberPlan_ModifiedByID]  DEFAULT ((-1)) FOR [ModifiedByID]
GO
ALTER TABLE [dbo].[tb_NumberPlan] ADD  CONSTRAINT [DF_tb_NumberPlan_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_NumberPlan]  WITH CHECK ADD  CONSTRAINT [FK_tb_NumberPlan_tb_NumberPlanType] FOREIGN KEY([NumberPlanTypeID])
REFERENCES [dbo].[tb_NumberPlanType] ([NumberPlanTypeID])
GO
ALTER TABLE [dbo].[tb_NumberPlan] CHECK CONSTRAINT [FK_tb_NumberPlan_tb_NumberPlanType]
GO
