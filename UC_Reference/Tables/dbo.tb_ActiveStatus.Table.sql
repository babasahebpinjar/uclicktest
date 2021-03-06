USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_ActiveStatus]    Script Date: 5/2/2020 6:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_ActiveStatus](
	[ActiveStatusID] [int] IDENTITY(1,1) NOT NULL,
	[ActiveStatus] [varchar](30) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_ActiveStatus] PRIMARY KEY CLUSTERED 
(
	[ActiveStatusID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_ActiveStatus] UNIQUE NONCLUSTERED 
(
	[ActiveStatus] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_ActiveStatus] ADD  CONSTRAINT [DF_tb_ActiveStatus_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_ActiveStatus] ADD  CONSTRAINT [DF_tb_ActiveStatus_Flag]  DEFAULT ((0)) FOR [Flag]
GO
