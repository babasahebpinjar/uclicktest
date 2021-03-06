USE [UC_Operations]
GO
/****** Object:  Table [dbo].[tb_WorkFlowTask]    Script Date: 5/2/2020 6:24:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_WorkFlowTask](
	[WorkFlowTaskID] [int] IDENTITY(1,1) NOT NULL,
	[WorkFlowID] [int] NOT NULL,
	[WorkFlowTaskName] [varchar](200) NOT NULL,
	[CallingProcedure] [varchar](200) NOT NULL,
	[CallingOrder] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NULL,
 CONSTRAINT [PK_tb_WorkFlowTask] PRIMARY KEY CLUSTERED 
(
	[WorkFlowTaskID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [uc_tb_WorkFlowTask_1] UNIQUE NONCLUSTERED 
(
	[WorkFlowTaskName] ASC,
	[WorkFlowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [uc_tb_WorkFlowTask_2] UNIQUE NONCLUSTERED 
(
	[CallingOrder] ASC,
	[WorkFlowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_WorkFlowTask]  WITH CHECK ADD  CONSTRAINT [FK_tb_WorkFlowTask_tb_WorkFlow] FOREIGN KEY([WorkFlowID])
REFERENCES [dbo].[tb_WorkFlow] ([WorkFlowID])
GO
ALTER TABLE [dbo].[tb_WorkFlowTask] CHECK CONSTRAINT [FK_tb_WorkFlowTask_tb_WorkFlow]
GO
