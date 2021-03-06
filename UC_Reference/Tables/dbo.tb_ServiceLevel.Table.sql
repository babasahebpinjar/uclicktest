USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_ServiceLevel]    Script Date: 5/2/2020 6:27:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_ServiceLevel](
	[ServiceLevelID] [int] IDENTITY(1,1) NOT NULL,
	[ServiceLevel] [varchar](60) NOT NULL,
	[ServiceLevelAbbrv] [varchar](20) NOT NULL,
	[RoutingFlag] [int] NOT NULL,
	[PriorityOrder] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
	[DirectionID] [int] NOT NULL,
 CONSTRAINT [PK_tb_ServiceLevel] PRIMARY KEY CLUSTERED 
(
	[ServiceLevelID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_ServiceLevel_Abbrv] UNIQUE NONCLUSTERED 
(
	[ServiceLevelAbbrv] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_ServiceLevel_Name] UNIQUE NONCLUSTERED 
(
	[ServiceLevel] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_ServiceLevel_Priority] UNIQUE NONCLUSTERED 
(
	[PriorityOrder] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_ServiceLevel] ADD  CONSTRAINT [DF_tb_ServiceLevel_RoutingFlag]  DEFAULT ((0)) FOR [RoutingFlag]
GO
ALTER TABLE [dbo].[tb_ServiceLevel] ADD  CONSTRAINT [DF_tb_ServiceLevel_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_ServiceLevel] ADD  CONSTRAINT [DF_tb_ServiceLevel_ModifiedByID]  DEFAULT ((1)) FOR [ModifiedByID]
GO
ALTER TABLE [dbo].[tb_ServiceLevel] ADD  CONSTRAINT [DF_tb_ServiceLevel_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_ServiceLevel] ADD  DEFAULT ((1)) FOR [DirectionID]
GO
ALTER TABLE [dbo].[tb_ServiceLevel]  WITH CHECK ADD  CONSTRAINT [FK_tb_ServiceLevel_tb_Direction] FOREIGN KEY([DirectionID])
REFERENCES [dbo].[tb_Direction] ([DirectionID])
GO
ALTER TABLE [dbo].[tb_ServiceLevel] CHECK CONSTRAINT [FK_tb_ServiceLevel_tb_Direction]
GO
