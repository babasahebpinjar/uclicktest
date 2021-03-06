USE [UC_Commerce]
GO
/****** Object:  Table [dbo].[tb_OfferStatusTransition]    Script Date: 5/2/2020 6:14:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_OfferStatusTransition](
	[OfferStatusTransitionID] [int] IDENTITY(1,1) NOT NULL,
	[FromOfferStatusID] [int] NOT NULL,
	[ToOfferStatusID] [int] NOT NULL,
	[OfferTypeID] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_OfferStatusTransition] PRIMARY KEY CLUSTERED 
(
	[OfferStatusTransitionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_OfferStatusTransition] UNIQUE NONCLUSTERED 
(
	[OfferTypeID] ASC,
	[FromOfferStatusID] ASC,
	[ToOfferStatusID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_OfferStatusTransition] ADD  CONSTRAINT [DF_tb_OfferStatusTransition_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_OfferStatusTransition] ADD  CONSTRAINT [DF_tb_OfferStatusTransition_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_OfferStatusTransition]  WITH CHECK ADD  CONSTRAINT [FK_tb_OfferStatusTransition_tb_Offerstatus] FOREIGN KEY([FromOfferStatusID])
REFERENCES [dbo].[tb_OfferStatus] ([OfferStatusID])
GO
ALTER TABLE [dbo].[tb_OfferStatusTransition] CHECK CONSTRAINT [FK_tb_OfferStatusTransition_tb_Offerstatus]
GO
ALTER TABLE [dbo].[tb_OfferStatusTransition]  WITH CHECK ADD  CONSTRAINT [FK_tb_OfferStatusTransition_tb_Offerstatus2] FOREIGN KEY([ToOfferStatusID])
REFERENCES [dbo].[tb_OfferStatus] ([OfferStatusID])
GO
ALTER TABLE [dbo].[tb_OfferStatusTransition] CHECK CONSTRAINT [FK_tb_OfferStatusTransition_tb_Offerstatus2]
GO
ALTER TABLE [dbo].[tb_OfferStatusTransition]  WITH CHECK ADD  CONSTRAINT [FK_tb_OfferStatusTransition_tb_Offertype] FOREIGN KEY([OfferTypeID])
REFERENCES [dbo].[tb_OfferType] ([OfferTypeID])
GO
ALTER TABLE [dbo].[tb_OfferStatusTransition] CHECK CONSTRAINT [FK_tb_OfferStatusTransition_tb_Offertype]
GO
