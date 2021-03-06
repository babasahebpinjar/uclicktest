USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_RatingScenarioType]    Script Date: 5/2/2020 6:27:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_RatingScenarioType](
	[RatingScenarioTypeID] [int] IDENTITY(1,1) NOT NULL,
	[RatingScenarioType] [varchar](60) NOT NULL,
	[RatingScenarioTypeAbbrv] [varchar](30) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_RatingScenarioType] PRIMARY KEY CLUSTERED 
(
	[RatingScenarioTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_RatingScenarioType] UNIQUE NONCLUSTERED 
(
	[RatingScenarioType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_RatingScenarioType] ADD  CONSTRAINT [DF_tb_RatingScenarioType_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_RatingScenarioType] ADD  CONSTRAINT [DF_tb_RatingScenarioType_Flag]  DEFAULT ((0)) FOR [Flag]
GO
