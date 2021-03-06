USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_EntityGroupType]    Script Date: 5/2/2020 6:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_EntityGroupType](
	[EntityGroupTypeID] [int] IDENTITY(1,1) NOT NULL,
	[EntityGroupType] [varchar](60) NOT NULL,
	[EntityGroupTypeAbbrv] [varchar](20) NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_EntityGroupType] PRIMARY KEY CLUSTERED 
(
	[EntityGroupTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_EntityGroupType] UNIQUE NONCLUSTERED 
(
	[EntityGroupType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_EntityGroupType] ADD  CONSTRAINT [DF_tb_EntityGroupType_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_EntityGroupType] ADD  CONSTRAINT [DF_tb_EntityGroupType_Flag]  DEFAULT ((0)) FOR [Flag]
GO
