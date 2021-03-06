USE [UC_Commerce]
GO
/****** Object:  Table [dbo].[tb_Source]    Script Date: 5/2/2020 6:14:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_Source](
	[SourceID] [int] IDENTITY(1,1) NOT NULL,
	[ActiveStatusID] [int] NOT NULL,
	[Source] [varchar](60) NOT NULL,
	[SourceAbbrv] [varchar](30) NOT NULL,
	[SourceTypeID] [int] NOT NULL,
	[NoteID] [int] NULL,
	[ExternalCode] [varchar](30) NULL,
	[RatePlanID] [int] NULL,
	[CurrencyID] [int] NULL,
	[ReferencePriceListID] [int] NULL,
	[ReferencePricingPolicyID] [int] NULL,
	[CallTypeID] [int] NULL,
	[ServiceLevelID] [int] NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_Source] PRIMARY KEY CLUSTERED 
(
	[SourceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [IX_tb_Source_1] UNIQUE NONCLUSTERED 
(
	[Source] ASC,
	[SourceTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_Source] ADD  CONSTRAINT [DF_tb_Source__ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_Source] ADD  CONSTRAINT [DF_tb_Source_Flag]  DEFAULT ((0)) FOR [Flag]
GO
