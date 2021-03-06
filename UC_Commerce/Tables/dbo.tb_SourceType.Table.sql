USE [UC_Commerce]
GO
/****** Object:  Table [dbo].[tb_SourceType]    Script Date: 5/2/2020 6:14:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_SourceType](
	[SourceTypeID] [int] NOT NULL,
	[SourceType] [varchar](60) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_SourceType] PRIMARY KEY CLUSTERED 
(
	[SourceTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_SourceType] ADD  CONSTRAINT [DF_tb_SourceType_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_SourceType] ADD  CONSTRAINT [DF_tb_SourceType_Flag]  DEFAULT ((0)) FOR [Flag]
GO
