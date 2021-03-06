USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_EntityGroupMember]    Script Date: 5/2/2020 6:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_EntityGroupMember](
	[EntityGroupMemberID] [int] IDENTITY(1,1) NOT NULL,
	[InstanceID] [int] NOT NULL,
	[EntityGroupID] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_EntityGroupMember] PRIMARY KEY CLUSTERED 
(
	[EntityGroupMemberID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_EntityGroupMember] UNIQUE NONCLUSTERED 
(
	[InstanceID] ASC,
	[EntityGroupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_EntityGroupMember] ADD  CONSTRAINT [DF_tb_EntityGroupMember_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_EntityGroupMember] ADD  CONSTRAINT [DF_tb_EntityGroupMember_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_EntityGroupMember]  WITH CHECK ADD  CONSTRAINT [FK_tb_EntityGroupMember_tb_EntityGroup] FOREIGN KEY([EntityGroupID])
REFERENCES [dbo].[tb_EntityGroup] ([EntityGroupID])
GO
ALTER TABLE [dbo].[tb_EntityGroupMember] CHECK CONSTRAINT [FK_tb_EntityGroupMember_tb_EntityGroup]
GO
