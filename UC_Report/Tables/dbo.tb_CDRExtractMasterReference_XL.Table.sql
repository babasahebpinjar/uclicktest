USE [UC_Report]
GO
/****** Object:  Table [dbo].[tb_CDRExtractMasterReference_XL]    Script Date: 5/2/2020 6:38:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_CDRExtractMasterReference_XL](
	[CDRExtractMasterReferenceID] [int] NOT NULL,
	[FieldName] [varchar](100) NOT NULL,
	[FieldType] [varchar](100) NOT NULL,
	[DataExtractSchema] [varchar](20) NOT NULL,
	[ExtractValue] [varchar](2000) NOT NULL,
	[JoinClause] [varchar](2000) NULL,
	[Flag] [int] NOT NULL
) ON [PRIMARY]
GO
