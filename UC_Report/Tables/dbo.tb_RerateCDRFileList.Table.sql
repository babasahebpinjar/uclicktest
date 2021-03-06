USE [UC_Report]
GO
/****** Object:  Table [dbo].[tb_RerateCDRFileList]    Script Date: 5/2/2020 6:38:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_RerateCDRFileList](
	[RerateID] [int] NOT NULL,
	[CDRFileID] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_RerateCDRFileList]  WITH CHECK ADD  CONSTRAINT [FK_tb_RerateCDRFileList_tb_Rerate] FOREIGN KEY([RerateID])
REFERENCES [dbo].[tb_Rerate] ([RerateID])
GO
ALTER TABLE [dbo].[tb_RerateCDRFileList] CHECK CONSTRAINT [FK_tb_RerateCDRFileList_tb_Rerate]
GO
