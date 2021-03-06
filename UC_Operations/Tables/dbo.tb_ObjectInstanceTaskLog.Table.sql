USE [UC_Operations]
GO
/****** Object:  Table [dbo].[tb_ObjectInstanceTaskLog]    Script Date: 5/2/2020 6:24:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_ObjectInstanceTaskLog](
	[ObjectInstanceTaskLogID] [varchar](100) NOT NULL,
	[ObjectInstanceID] [int] NOT NULL,
	[TaskName] [varchar](500) NOT NULL,
	[TaskStartDate] [datetime] NULL,
	[TaskEndDate] [datetime] NULL,
	[CommentLog] [varchar](2000) NULL,
	[Measure1] [int] NULL,
	[Measure2] [int] NULL,
	[Measure3] [int] NULL,
	[Measure4] [int] NULL,
	[Measure5] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_ObjectInstanceTaskLog]  WITH CHECK ADD  CONSTRAINT [FK_tb_ObjInstTaskLog_tb_ObjectInstance] FOREIGN KEY([ObjectInstanceID])
REFERENCES [dbo].[tb_ObjectInstance] ([ObjectInstanceID])
GO
ALTER TABLE [dbo].[tb_ObjectInstanceTaskLog] CHECK CONSTRAINT [FK_tb_ObjInstTaskLog_tb_ObjectInstance]
GO
