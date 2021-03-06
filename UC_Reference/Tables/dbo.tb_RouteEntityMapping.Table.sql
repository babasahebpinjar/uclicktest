USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_RouteEntityMapping]    Script Date: 5/2/2020 6:27:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_RouteEntityMapping](
	[RouteEntityMappingID] [int] IDENTITY(1,1) NOT NULL,
	[ReferenceDestinationID] [int] NOT NULL,
	[CalltypeID] [int] NOT NULL,
	[RateDimensionTemplateID] [int] NOT NULL,
	[BeginDate] [datetime] NOT NULL,
	[EndDate] [datetime] NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_RouteEntityMapping] PRIMARY KEY CLUSTERED 
(
	[RouteEntityMappingID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_RouteEntityMapping] UNIQUE NONCLUSTERED 
(
	[ReferenceDestinationID] ASC,
	[CalltypeID] ASC,
	[BeginDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_RouteEntityMapping] ADD  CONSTRAINT [DF_tb_RouteEntityMapping_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_RouteEntityMapping] ADD  CONSTRAINT [DF_tb_RouteEntityMapping_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_RouteEntityMapping]  WITH CHECK ADD  CONSTRAINT [FK_tb_RouteEntityMapping_tb_CallType] FOREIGN KEY([CalltypeID])
REFERENCES [dbo].[tb_CallType] ([CallTypeID])
GO
ALTER TABLE [dbo].[tb_RouteEntityMapping] CHECK CONSTRAINT [FK_tb_RouteEntityMapping_tb_CallType]
GO
ALTER TABLE [dbo].[tb_RouteEntityMapping]  WITH CHECK ADD  CONSTRAINT [FK_tb_RouteEntityMapping_tb_Destination] FOREIGN KEY([ReferenceDestinationID])
REFERENCES [dbo].[tb_Destination] ([DestinationID])
GO
ALTER TABLE [dbo].[tb_RouteEntityMapping] CHECK CONSTRAINT [FK_tb_RouteEntityMapping_tb_Destination]
GO
ALTER TABLE [dbo].[tb_RouteEntityMapping]  WITH CHECK ADD  CONSTRAINT [FK_tb_RouteEntityMapping_tb_RateDimensionTemplate] FOREIGN KEY([RateDimensionTemplateID])
REFERENCES [dbo].[tb_RateDimensionTemplate] ([RateDimensionTemplateID])
GO
ALTER TABLE [dbo].[tb_RouteEntityMapping] CHECK CONSTRAINT [FK_tb_RouteEntityMapping_tb_RateDimensionTemplate]
GO
