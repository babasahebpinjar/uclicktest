USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_RateStructure]    Script Date: 5/2/2020 6:27:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_RateStructure](
	[RateStructureID] [int] IDENTITY(0,1) NOT NULL,
	[RateStructure] [varchar](100) NOT NULL,
	[RateStructureAbbrv] [varchar](60) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_RateStructure] PRIMARY KEY CLUSTERED 
(
	[RateStructureID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_RateStructure] ADD  CONSTRAINT [DF_tb_RateStructure_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_RateStructure] ADD  CONSTRAINT [DF_tb_RateStructure_Flag]  DEFAULT ((0)) FOR [Flag]
GO
