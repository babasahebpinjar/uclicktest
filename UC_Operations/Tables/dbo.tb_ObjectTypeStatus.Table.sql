USE [UC_Operations]
GO
/****** Object:  Table [dbo].[tb_ObjectTypeStatus]    Script Date: 5/2/2020 6:24:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_ObjectTypeStatus](
	[ObjectTypeStatusID] [int] IDENTITY(1,1) NOT NULL,
	[ObjectTypeID] [int] NOT NULL,
	[StatusID] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NULL,
 CONSTRAINT [PK_tb_ObjectTypeStatus] PRIMARY KEY CLUSTERED 
(
	[ObjectTypeStatusID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [uc_tb_ObjectTypeStatus] UNIQUE NONCLUSTERED 
(
	[ObjectTypeID] ASC,
	[StatusID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_ObjectTypeStatus]  WITH CHECK ADD  CONSTRAINT [FK_tb_ObjectTypeStatus_tb_ObjectType] FOREIGN KEY([ObjectTypeID])
REFERENCES [dbo].[tb_ObjectType] ([ObjectTypeID])
GO
ALTER TABLE [dbo].[tb_ObjectTypeStatus] CHECK CONSTRAINT [FK_tb_ObjectTypeStatus_tb_ObjectType]
GO
ALTER TABLE [dbo].[tb_ObjectTypeStatus]  WITH CHECK ADD  CONSTRAINT [FK_tb_ObjectTypeStatus_tb_status] FOREIGN KEY([StatusID])
REFERENCES [dbo].[tb_Status] ([StatusID])
GO
ALTER TABLE [dbo].[tb_ObjectTypeStatus] CHECK CONSTRAINT [FK_tb_ObjectTypeStatus_tb_status]
GO
