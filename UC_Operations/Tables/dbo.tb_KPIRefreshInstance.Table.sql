USE [UC_Operations]
GO
/****** Object:  Table [dbo].[tb_KPIRefreshInstance]    Script Date: 5/2/2020 6:24:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_KPIRefreshInstance](
	[KPIRefreshInstanceID] [int] IDENTITY(1,1) NOT NULL,
	[ObjectInstanceID] [int] NOT NULL,
	[CallDate] [datetime] NOT NULL,
	[KPIRefreshBatchID] [int] NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NULL,
	[SuccessRecords] [int] NULL,
	[FailedRecords] [int] NULL,
 CONSTRAINT [PK_tb_KPIRefreshInstance] PRIMARY KEY CLUSTERED 
(
	[KPIRefreshInstanceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_KPIRefreshInstance]  WITH CHECK ADD  CONSTRAINT [FK_tb_KPIRefreshInstance_tb_ObjectInstance] FOREIGN KEY([KPIRefreshBatchID])
REFERENCES [dbo].[tb_ObjectInstance] ([ObjectInstanceID])
GO
ALTER TABLE [dbo].[tb_KPIRefreshInstance] CHECK CONSTRAINT [FK_tb_KPIRefreshInstance_tb_ObjectInstance]
GO
