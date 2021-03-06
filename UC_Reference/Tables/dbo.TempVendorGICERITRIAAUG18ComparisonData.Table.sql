USE [UC_Reference]
GO
/****** Object:  Table [dbo].[TempVendorGICERITRIAAUG18ComparisonData]    Script Date: 5/2/2020 6:27:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TempVendorGICERITRIAAUG18ComparisonData](
	[CallingNumber] [varchar](60) NULL,
	[CalledNumber] [varchar](60) NULL,
	[CallDuration] [decimal](19, 2) NULL,
	[SettlementDestination] [varchar](100) NULL,
	[CallDate] [varchar](30) NULL,
	[RecSeqNum] [int] IDENTITY(1,1) NOT NULL,
	[RecordStatus] [varchar](20) NULL
) ON [PRIMARY]
GO
