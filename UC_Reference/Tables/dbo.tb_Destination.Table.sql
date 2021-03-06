USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_Destination]    Script Date: 5/2/2020 6:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_Destination](
	[DestinationID] [int] IDENTITY(1,1) NOT NULL,
	[Destination] [varchar](60) NOT NULL,
	[DestinationAbbrv] [varchar](20) NOT NULL,
	[DestinationTypeID] [int] NOT NULL,
	[InternalCode] [varchar](10) NULL,
	[ExternalCode] [varchar](10) NULL,
	[BeginDate] [datetime] NOT NULL,
	[EndDate] [datetime] NULL,
	[NumberPlanID] [int] NOT NULL,
	[CountryID] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_Destination] PRIMARY KEY CLUSTERED 
(
	[DestinationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_Destination] ADD  CONSTRAINT [DF_tb_Destination_DestinationTypeID]  DEFAULT ((1)) FOR [DestinationTypeID]
GO
ALTER TABLE [dbo].[tb_Destination] ADD  CONSTRAINT [DF_tb_Destination_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_Destination] ADD  CONSTRAINT [DF_tb_Destination_flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_Destination]  WITH CHECK ADD  CONSTRAINT [FK_tb_Destination_tb_Country] FOREIGN KEY([CountryID])
REFERENCES [dbo].[tb_Country] ([CountryID])
GO
ALTER TABLE [dbo].[tb_Destination] CHECK CONSTRAINT [FK_tb_Destination_tb_Country]
GO
ALTER TABLE [dbo].[tb_Destination]  WITH CHECK ADD  CONSTRAINT [FK_tb_Destination_tb_DestinationType] FOREIGN KEY([DestinationTypeID])
REFERENCES [dbo].[tb_DestinationType] ([DestinationTypeID])
GO
ALTER TABLE [dbo].[tb_Destination] CHECK CONSTRAINT [FK_tb_Destination_tb_DestinationType]
GO
ALTER TABLE [dbo].[tb_Destination]  WITH CHECK ADD  CONSTRAINT [FK_tb_Destination_tb_NumberPlan] FOREIGN KEY([NumberPlanID])
REFERENCES [dbo].[tb_NumberPlan] ([NumberPlanID])
GO
ALTER TABLE [dbo].[tb_Destination] CHECK CONSTRAINT [FK_tb_Destination_tb_NumberPlan]
GO
