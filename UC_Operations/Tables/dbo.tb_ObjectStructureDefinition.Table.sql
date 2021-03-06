USE [UC_Operations]
GO
/****** Object:  Table [dbo].[tb_ObjectStructureDefinition]    Script Date: 5/2/2020 6:24:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_ObjectStructureDefinition](
	[ObjectStructureDefinitionID] [int] IDENTITY(1,1) NOT NULL,
	[ObjectStructureID] [int] NOT NULL,
	[FieldName] [varchar](200) NOT NULL,
	[FieldOrder] [int] NOT NULL,
	[FieldType] [varchar](100) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
 CONSTRAINT [PK_tb_ObjectStructureDefinition] PRIMARY KEY CLUSTERED 
(
	[ObjectStructureDefinitionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_ObjectStructureDefinitionID_1] UNIQUE NONCLUSTERED 
(
	[ObjectStructureID] ASC,
	[FieldName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_ObjectStructureDefinitionID_2] UNIQUE NONCLUSTERED 
(
	[ObjectStructureID] ASC,
	[FieldOrder] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_ObjectStructureDefinition]  WITH CHECK ADD  CONSTRAINT [FK_tb_ObjectStructureDefinition_tb_ObjectStructure] FOREIGN KEY([ObjectStructureID])
REFERENCES [dbo].[tb_ObjectStructure] ([ObjectStructureID])
GO
ALTER TABLE [dbo].[tb_ObjectStructureDefinition] CHECK CONSTRAINT [FK_tb_ObjectStructureDefinition_tb_ObjectStructure]
GO
