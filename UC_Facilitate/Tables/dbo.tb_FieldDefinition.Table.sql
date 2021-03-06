USE [UC_Facilitate]
GO
/****** Object:  Table [dbo].[tb_FieldDefinition]    Script Date: 5/2/2020 6:47:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_FieldDefinition](
	[FieldDefinitionID] [int] IDENTITY(1,1) NOT NULL,
	[FileDefinitionID] [int] NOT NULL,
	[FieldName] [varchar](200) NOT NULL,
	[FieldOrder] [int] NOT NULL,
	[FieldType] [varchar](100) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
 CONSTRAINT [PK_tb_FieldDefinition] PRIMARY KEY CLUSTERED 
(
	[FieldDefinitionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_FieldDefinition_1] UNIQUE NONCLUSTERED 
(
	[FileDefinitionID] ASC,
	[FieldName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_FieldDefinition_2] UNIQUE NONCLUSTERED 
(
	[FileDefinitionID] ASC,
	[FieldOrder] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_FieldDefinition]  WITH CHECK ADD  CONSTRAINT [FK_tb_FieldDefinition_tb_FileDefinition] FOREIGN KEY([FileDefinitionID])
REFERENCES [dbo].[tb_FileDefinition] ([FileDefinitionID])
GO
ALTER TABLE [dbo].[tb_FieldDefinition] CHECK CONSTRAINT [FK_tb_FieldDefinition_tb_FileDefinition]
GO
