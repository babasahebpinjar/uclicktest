USE [UC_Commerce]
GO
/****** Object:  Table [dbo].[tb_OfferWorkflow]    Script Date: 5/2/2020 6:14:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_OfferWorkflow](
	[OfferWorkflowID] [int] IDENTITY(1,1) NOT NULL,
	[OfferID] [int] NOT NULL,
	[OfferStatusID] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_OfferWorkflow] PRIMARY KEY CLUSTERED 
(
	[OfferWorkflowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_OfferWorkflow] ADD  CONSTRAINT [DF_tb_OfferWorkflow_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_OfferWorkflow] ADD  CONSTRAINT [DF_tb_OfferWorkflow_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_OfferWorkflow]  WITH CHECK ADD  CONSTRAINT [FK_tb_OfferWorkflow_tb_Offer] FOREIGN KEY([OfferID])
REFERENCES [dbo].[tb_Offer] ([OfferID])
GO
ALTER TABLE [dbo].[tb_OfferWorkflow] CHECK CONSTRAINT [FK_tb_OfferWorkflow_tb_Offer]
GO
ALTER TABLE [dbo].[tb_OfferWorkflow]  WITH CHECK ADD  CONSTRAINT [FK_tb_OfferWorkflow_tb_OfferStatus] FOREIGN KEY([OfferStatusID])
REFERENCES [dbo].[tb_OfferStatus] ([OfferStatusID])
GO
ALTER TABLE [dbo].[tb_OfferWorkflow] CHECK CONSTRAINT [FK_tb_OfferWorkflow_tb_OfferStatus]
GO
