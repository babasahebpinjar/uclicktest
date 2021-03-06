USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_TrunkType]    Script Date: 5/2/2020 6:27:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_TrunkType](
	[TrunkTypeID] [int] IDENTITY(1,1) NOT NULL,
	[TrunkType] [varchar](60) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_TrunkType] PRIMARY KEY CLUSTERED 
(
	[TrunkTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_TrunkType] UNIQUE NONCLUSTERED 
(
	[TrunkType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_TrunkType] ADD  CONSTRAINT [DF_tb_TrunkType_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_TrunkType] ADD  CONSTRAINT [DF_tb_TrunkType_Flag]  DEFAULT ((0)) FOR [Flag]
GO
