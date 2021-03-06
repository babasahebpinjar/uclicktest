USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_ThresholdAlertTable]    Script Date: 5/2/2020 6:27:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_ThresholdAlertTable](
	[ThresholdAlertID] [int] IDENTITY(1,1) NOT NULL,
	[AccountID] [int] NULL,
	[CreditBalance] [float] NULL,
	[AlertType] [int] NULL,
	[AlertDate] [datetime] NULL,
	[AlertStatus] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_ThresholdAlertTable]  WITH CHECK ADD FOREIGN KEY([AccountID])
REFERENCES [dbo].[tb_Account] ([AccountID])
GO
