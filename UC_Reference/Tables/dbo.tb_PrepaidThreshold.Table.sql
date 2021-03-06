USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_PrepaidThreshold]    Script Date: 5/2/2020 6:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_PrepaidThreshold](
	[PrepaidThresholdID] [int] IDENTITY(1,1) NOT NULL,
	[AccountID] [int] NOT NULL,
	[Threshold_1] [int] NOT NULL,
	[Threshold_2] [int] NOT NULL,
	[BeginDate] [datetime] NOT NULL,
	[EndDate] [datetime] NULL,
	[ModifiedByID] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_tb_PrepaidThreshold] PRIMARY KEY CLUSTERED 
(
	[PrepaidThresholdID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_PrepaidThreshold] ADD  CONSTRAINT [DF_tb_PrepaidThreshold_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_PrepaidThreshold]  WITH CHECK ADD  CONSTRAINT [FK_tb_PrepaidThreshold_tb_Account] FOREIGN KEY([AccountID])
REFERENCES [dbo].[tb_Account] ([AccountID])
GO
ALTER TABLE [dbo].[tb_PrepaidThreshold] CHECK CONSTRAINT [FK_tb_PrepaidThreshold_tb_Account]
GO
