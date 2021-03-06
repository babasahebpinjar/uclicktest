USE [UC_Report]
GO
/****** Object:  Table [dbo].[tb_CDRExtractParamList]    Script Date: 5/2/2020 6:38:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_CDRExtractParamList](
	[CDRExtractParamListID] [int] IDENTITY(1,1) NOT NULL,
	[CDRExtractID] [int] NOT NULL,
	[BeginDate] [datetime] NOT NULL,
	[EndDate] [datetime] NOT NULL,
	[CallTypeID] [int] NOT NULL,
	[INAccountList] [varchar](2000) NOT NULL,
	[OUTAccountList] [varchar](2000) NOT NULL,
	[INCommercialTrunkList] [varchar](2000) NOT NULL,
	[OUTCommercialTrunkList] [varchar](2000) NOT NULL,
	[INTechnicalTrunkList] [varchar](2000) NOT NULL,
	[OUTTechnicalTrunkList] [varchar](2000) NOT NULL,
	[CountryList] [varchar](2000) NOT NULL,
	[DestinationList] [varchar](2000) NOT NULL,
	[ServiceLevelList] [varchar](2000) NOT NULL,
	[ConditionClause] [varchar](2000) NULL,
	[DisplayFieldList] [varchar](2000) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
 CONSTRAINT [PK_tb_CDRExtractParamList] PRIMARY KEY CLUSTERED 
(
	[CDRExtractParamListID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_CDRExtractParamList] UNIQUE NONCLUSTERED 
(
	[CDRExtractID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_CDRExtractParamList]  WITH CHECK ADD  CONSTRAINT [FK_tb_CDRExtractParamList_tb_CDRExtract] FOREIGN KEY([CDRExtractID])
REFERENCES [dbo].[tb_CDRExtract] ([CDRExtractID])
GO
ALTER TABLE [dbo].[tb_CDRExtractParamList] CHECK CONSTRAINT [FK_tb_CDRExtractParamList_tb_CDRExtract]
GO
