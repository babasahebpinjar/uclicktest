USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_ExternalNetworkTransaction]    Script Date: 5/2/2020 6:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_ExternalNetworkTransaction](
	[ExternalNetworkTransactionID] [int] IDENTITY(1,1) NOT NULL,
	[TransactionReason] [varchar](200) NOT NULL,
	[ActionRegisterDate] [datetime] NOT NULL,
	[ActionCompletionDate] [datetime] NULL,
	[ActionStatusID] [int] NOT NULL,
	[Remarks] [varchar](2000) NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
 CONSTRAINT [PK_tb_ExternalNetworkTransaction] PRIMARY KEY CLUSTERED 
(
	[ExternalNetworkTransactionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_ExternalNetworkTransaction]  WITH CHECK ADD  CONSTRAINT [FK_tb_ExternalNetworkTransaction_tb_ExternalNetworkTransactionActionStatus] FOREIGN KEY([ActionStatusID])
REFERENCES [dbo].[tb_ExternalNetworkActionStatus] ([ExternalNetworkActionStatusID])
GO
ALTER TABLE [dbo].[tb_ExternalNetworkTransaction] CHECK CONSTRAINT [FK_tb_ExternalNetworkTransaction_tb_ExternalNetworkTransactionActionStatus]
GO
