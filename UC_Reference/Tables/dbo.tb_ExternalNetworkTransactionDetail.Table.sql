USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_ExternalNetworkTransactionDetail]    Script Date: 5/2/2020 6:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_ExternalNetworkTransactionDetail](
	[ExternalNetworkTransactionDetailID] [int] IDENTITY(1,1) NOT NULL,
	[ExternalNetworkTransactionID] [int] NOT NULL,
	[ElementTypeID] [int] NOT NULL,
	[ElementID] [int] NOT NULL,
	[EntityStatus] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
 CONSTRAINT [PK_tb_ExternalNetworkTransactionDetail] PRIMARY KEY CLUSTERED 
(
	[ExternalNetworkTransactionDetailID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_ExternalNetworkTransactionDetail]  WITH CHECK ADD  CONSTRAINT [FK_tb_ExternalNetworkTransactionDetail_tb_ElementType] FOREIGN KEY([ElementTypeID])
REFERENCES [dbo].[tb_ElementType] ([ElementTypeID])
GO
ALTER TABLE [dbo].[tb_ExternalNetworkTransactionDetail] CHECK CONSTRAINT [FK_tb_ExternalNetworkTransactionDetail_tb_ElementType]
GO
ALTER TABLE [dbo].[tb_ExternalNetworkTransactionDetail]  WITH CHECK ADD  CONSTRAINT [FK_tb_ExternalNetworkTransactionDetail_tb_ExternalNetworkTransaction] FOREIGN KEY([ExternalNetworkTransactionID])
REFERENCES [dbo].[tb_ExternalNetworkTransaction] ([ExternalNetworkTransactionID])
GO
ALTER TABLE [dbo].[tb_ExternalNetworkTransactionDetail] CHECK CONSTRAINT [FK_tb_ExternalNetworkTransactionDetail_tb_ExternalNetworkTransaction]
GO
