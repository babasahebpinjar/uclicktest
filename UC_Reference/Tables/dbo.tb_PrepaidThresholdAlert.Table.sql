USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_PrepaidThresholdAlert]    Script Date: 5/2/2020 6:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_PrepaidThresholdAlert](
	[AccountID] [int] NOT NULL,
	[CreditBalance] [decimal](19, 2) NOT NULL,
	[ThresholdAmount] [decimal](19, 2) NOT NULL,
	[AlertTypeID] [int] NOT NULL,
	[AlertDate] [datetime] NOT NULL,
	[AlertStatusID] [int] NOT NULL
) ON [PRIMARY]
GO
