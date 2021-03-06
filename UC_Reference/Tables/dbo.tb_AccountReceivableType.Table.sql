USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_AccountReceivableType]    Script Date: 5/2/2020 6:27:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_AccountReceivableType](
	[AccountReceivableTypeID] [int] IDENTITY(1,1) NOT NULL,
	[AccountReceivableType] [varchar](60) NOT NULL,
	[AccountReceivableTypeAbbrv] [varchar](20) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_AccountReceivableType] PRIMARY KEY CLUSTERED 
(
	[AccountReceivableTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_AccountReceivableType] UNIQUE NONCLUSTERED 
(
	[AccountReceivableType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_AccountReceivableType] ADD  CONSTRAINT [DF_tb_AccountReceivableType_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_AccountReceivableType] ADD  CONSTRAINT [DF_tb_AccountReceivableType_Flag]  DEFAULT ((0)) FOR [Flag]
GO
