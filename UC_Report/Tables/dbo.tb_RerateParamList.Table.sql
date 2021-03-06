USE [UC_Report]
GO
/****** Object:  Table [dbo].[tb_RerateParamList]    Script Date: 5/2/2020 6:38:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_RerateParamList](
	[RerateParamListID] [int] IDENTITY(1,1) NOT NULL,
	[RerateID] [int] NOT NULL,
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
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
 CONSTRAINT [PK_tb_RerateParamList] PRIMARY KEY CLUSTERED 
(
	[RerateParamListID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_RerateParamList] UNIQUE NONCLUSTERED 
(
	[RerateID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_RerateParamList]  WITH CHECK ADD  CONSTRAINT [FK_tb_RerateParamList_tb_Rerate] FOREIGN KEY([RerateID])
REFERENCES [dbo].[tb_Rerate] ([RerateID])
GO
ALTER TABLE [dbo].[tb_RerateParamList] CHECK CONSTRAINT [FK_tb_RerateParamList_tb_Rerate]
GO
