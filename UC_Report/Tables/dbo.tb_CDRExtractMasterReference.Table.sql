USE [UC_Report]
GO
/****** Object:  Table [dbo].[tb_CDRExtractMasterReference]    Script Date: 5/2/2020 6:38:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_CDRExtractMasterReference](
	[CDRExtractMasterReferenceID] [int] NOT NULL,
	[FieldName] [varchar](100) NOT NULL,
	[FieldType] [varchar](100) NOT NULL,
	[DataExtractSchema] [varchar](20) NOT NULL,
	[ExtractValue] [varchar](2000) NOT NULL,
	[JoinClause] [varchar](2000) NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_CDRExtractMasterReference] PRIMARY KEY CLUSTERED 
(
	[CDRExtractMasterReferenceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_CDRExtractMasterReference] UNIQUE NONCLUSTERED 
(
	[FieldName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_CDRExtractMasterReference]  WITH CHECK ADD  CONSTRAINT [VK_DataExtractSchema_tb_CDRExtractMasterReference] CHECK  (([DataExtractSchema]='FTR' OR [DataExtractSchema]='CDR'))
GO
ALTER TABLE [dbo].[tb_CDRExtractMasterReference] CHECK CONSTRAINT [VK_DataExtractSchema_tb_CDRExtractMasterReference]
GO
