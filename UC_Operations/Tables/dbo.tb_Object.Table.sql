USE [UC_Operations]
GO
/****** Object:  Table [dbo].[tb_Object]    Script Date: 5/2/2020 6:24:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_Object](
	[ObjectID] [int] IDENTITY(1,1) NOT NULL,
	[ObjectTypeID] [int] NOT NULL,
	[ObjectName] [varchar](100) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NULL,
 CONSTRAINT [PK_tb_Object] PRIMARY KEY CLUSTERED 
(
	[ObjectID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [uc_ObjectName] UNIQUE NONCLUSTERED 
(
	[ObjectName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_Object]  WITH CHECK ADD  CONSTRAINT [FK_tb_Object_tb_ObjectType] FOREIGN KEY([ObjectTypeID])
REFERENCES [dbo].[tb_ObjectType] ([ObjectTypeID])
GO
ALTER TABLE [dbo].[tb_Object] CHECK CONSTRAINT [FK_tb_Object_tb_ObjectType]
GO
