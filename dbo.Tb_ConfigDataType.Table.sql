USE [UC_Admin]
GO
/****** Object:  Table [dbo].[Tb_ConfigDataType]    Script Date: 02-05-2020 14:39:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tb_ConfigDataType](
	[ConfigDataTypeID] [int] IDENTITY(1,1) NOT NULL,
	[configdatatype] [varchar](1000) NOT NULL,
 CONSTRAINT [uc_ConfigDataTypeID] UNIQUE NONCLUSTERED 
(
	[ConfigDataTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
