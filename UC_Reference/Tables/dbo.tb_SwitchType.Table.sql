USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_SwitchType]    Script Date: 5/2/2020 6:27:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_SwitchType](
	[SwitchTypeID] [int] IDENTITY(1,1) NOT NULL,
	[SwitchType] [varchar](60) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_SwitchType] PRIMARY KEY CLUSTERED 
(
	[SwitchTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_SwitchType] UNIQUE NONCLUSTERED 
(
	[SwitchType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_SwitchType] ADD  CONSTRAINT [DF_tb_SwitchType_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_SwitchType] ADD  CONSTRAINT [DF_tb_SwitchType_Flag]  DEFAULT ((0)) FOR [Flag]
GO
