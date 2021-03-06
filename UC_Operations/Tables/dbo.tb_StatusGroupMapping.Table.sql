USE [UC_Operations]
GO
/****** Object:  Table [dbo].[tb_StatusGroupMapping]    Script Date: 5/2/2020 6:24:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_StatusGroupMapping](
	[StatusGroupMappingID] [int] IDENTITY(1,1) NOT NULL,
	[StatusGroupID] [int] NOT NULL,
	[StatusID] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NULL,
 CONSTRAINT [PK_tb_StatusGroupMapping] PRIMARY KEY CLUSTERED 
(
	[StatusGroupMappingID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [uc_tb_StatusGroupMapping] UNIQUE NONCLUSTERED 
(
	[StatusGroupID] ASC,
	[StatusID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_StatusGroupMapping]  WITH CHECK ADD  CONSTRAINT [FK_tb_StatusGroupMapping_tb_status] FOREIGN KEY([StatusID])
REFERENCES [dbo].[tb_Status] ([StatusID])
GO
ALTER TABLE [dbo].[tb_StatusGroupMapping] CHECK CONSTRAINT [FK_tb_StatusGroupMapping_tb_status]
GO
ALTER TABLE [dbo].[tb_StatusGroupMapping]  WITH CHECK ADD  CONSTRAINT [FK_tb_StatusGroupMapping_tb_StatusGroup] FOREIGN KEY([StatusGroupID])
REFERENCES [dbo].[tb_StatusGroup] ([StatusGroupID])
GO
ALTER TABLE [dbo].[tb_StatusGroupMapping] CHECK CONSTRAINT [FK_tb_StatusGroupMapping_tb_StatusGroup]
GO
