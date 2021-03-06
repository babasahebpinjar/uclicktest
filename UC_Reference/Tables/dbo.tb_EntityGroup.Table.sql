USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_EntityGroup]    Script Date: 5/2/2020 6:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_EntityGroup](
	[EntityGroupID] [int] IDENTITY(1,1) NOT NULL,
	[EntityGroup] [varchar](60) NOT NULL,
	[EntityGroupAbbrv] [varchar](20) NOT NULL,
	[EntityGroupTypeID] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_EntityGroup] PRIMARY KEY CLUSTERED 
(
	[EntityGroupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_EntityGroup] UNIQUE NONCLUSTERED 
(
	[EntityGroup] ASC,
	[EntityGroupTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_EntityGroup] ADD  CONSTRAINT [DF_tb_EntityGroup_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_EntityGroup] ADD  CONSTRAINT [DF_tb_EntityGroup_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_EntityGroup]  WITH CHECK ADD  CONSTRAINT [FK_tb_EntityGroup_tb_EntityGroupType] FOREIGN KEY([EntityGroupTypeID])
REFERENCES [dbo].[tb_EntityGroupType] ([EntityGroupTypeID])
GO
ALTER TABLE [dbo].[tb_EntityGroup] CHECK CONSTRAINT [FK_tb_EntityGroup_tb_EntityGroupType]
GO
