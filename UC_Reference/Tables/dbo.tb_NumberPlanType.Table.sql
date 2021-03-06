USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_NumberPlanType]    Script Date: 5/2/2020 6:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_NumberPlanType](
	[NumberPlanTypeID] [int] IDENTITY(1,1) NOT NULL,
	[NumberPlanType] [varchar](100) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_NumberPlanType] PRIMARY KEY CLUSTERED 
(
	[NumberPlanTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_NumberPlanType] UNIQUE NONCLUSTERED 
(
	[NumberPlanType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_NumberPlanType] ADD  CONSTRAINT [DF_tb_NumberPlanType_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_NumberPlanType] ADD  CONSTRAINT [DF_tb_NumberPlanType_ModifiedByID]  DEFAULT ((-1)) FOR [ModifiedByID]
GO
ALTER TABLE [dbo].[tb_NumberPlanType] ADD  CONSTRAINT [DF_tb_NumberPlanType_Flag]  DEFAULT ((0)) FOR [Flag]
GO
