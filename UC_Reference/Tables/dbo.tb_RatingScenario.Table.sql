USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_RatingScenario]    Script Date: 5/2/2020 6:27:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_RatingScenario](
	[RatingScenarioID] [int] IDENTITY(1,1) NOT NULL,
	[RatingScenarioName] [varchar](100) NULL,
	[RatingScenarioTypeID] [int] NOT NULL,
	[RatingScenarioDescription] [varchar](255) NULL,
	[Attribute1ID] [int] NULL,
	[Attribute2ID] [int] NULL,
	[Attribute3ID] [int] NULL,
	[Attribute4ID] [int] NULL,
	[Attribute5ID] [int] NULL,
	[Attribute6ID] [int] NULL,
	[Attribute7ID] [int] NULL,
	[Attribute8ID] [int] NULL,
	[Attribute9ID] [int] NULL,
	[Attribute10ID] [int] NULL,
	[Attribute11ID] [int] NULL,
	[Attribute12ID] [int] NULL,
	[Attribute13ID] [int] NULL,
	[Attribute14ID] [int] NULL,
	[Attribute15ID] [int] NULL,
	[Result1ID] [int] NULL,
	[Result2ID] [int] NULL,
	[Result3ID] [int] NULL,
	[NoteID] [int] NULL,
	[BeginDate] [datetime] NOT NULL,
	[EndDate] [datetime] NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_RatingScenario] PRIMARY KEY CLUSTERED 
(
	[RatingScenarioID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_RatingScenario] ADD  CONSTRAINT [DF_tb_RatingScenario_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_RatingScenario] ADD  CONSTRAINT [DF_tb_RatingScenario_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_RatingScenario]  WITH CHECK ADD  CONSTRAINT [FK_tb_RatingScenario_tb_RatingScenarioType] FOREIGN KEY([RatingScenarioTypeID])
REFERENCES [dbo].[tb_RatingScenarioType] ([RatingScenarioTypeID])
GO
ALTER TABLE [dbo].[tb_RatingScenario] CHECK CONSTRAINT [FK_tb_RatingScenario_tb_RatingScenarioType]
GO
