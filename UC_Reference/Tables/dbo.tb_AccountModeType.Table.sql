USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_AccountModeType]    Script Date: 5/2/2020 6:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_AccountModeType](
	[AccountModeTypeID] [int] IDENTITY(1,1) NOT NULL,
	[AccountModeType] [varchar](100) NOT NULL,
	[AccountModeTypeAbbrv] [varchar](50) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_AccountModeType] PRIMARY KEY CLUSTERED 
(
	[AccountModeTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_AccountModeType] UNIQUE NONCLUSTERED 
(
	[AccountModeType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_AccountModeType] ADD  CONSTRAINT [DF_tb_AccountModeType_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_AccountModeType] ADD  CONSTRAINT [DF_tb_AccountModeType_ModifiedByID]  DEFAULT ((-1)) FOR [ModifiedByID]
GO
ALTER TABLE [dbo].[tb_AccountModeType] ADD  CONSTRAINT [DF_tb_AccountModeType_Flag]  DEFAULT ((0)) FOR [Flag]
GO
