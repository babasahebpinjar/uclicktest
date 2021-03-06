USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_ChargeType]    Script Date: 5/2/2020 6:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_ChargeType](
	[ChargeTypeID] [int] IDENTITY(1,1) NOT NULL,
	[ChargeType] [varchar](30) NULL,
	[ChargeTypeAbbrv] [varchar](16) NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_ChargeType] PRIMARY KEY CLUSTERED 
(
	[ChargeTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_ChargeType] UNIQUE NONCLUSTERED 
(
	[ChargeType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_ChargeType] ADD  CONSTRAINT [DF_tb_ChargeType_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_ChargeType] ADD  CONSTRAINT [DF_tb_ChargeType_Flag]  DEFAULT ((0)) FOR [Flag]
GO
