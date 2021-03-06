USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_DialedDigits]    Script Date: 5/2/2020 6:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_DialedDigits](
	[DialedDigitsID] [int] IDENTITY(1,1) NOT NULL,
	[DialedDigits] [varchar](60) NOT NULL,
	[IntIndicator] [char](10) NOT NULL,
	[NumberPlanID] [int] NOT NULL,
	[DestinationID] [int] NOT NULL,
	[BeginDate] [datetime] NOT NULL,
	[EndDate] [datetime] NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_DialedDigits] PRIMARY KEY CLUSTERED 
(
	[DialedDigitsID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_DialedDigits] ADD  CONSTRAINT [DF_tb_DialedDigits_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_DialedDigits] ADD  CONSTRAINT [DF_tb_DialedDigits_flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_DialedDigits]  WITH CHECK ADD  CONSTRAINT [FK_tb_DialedDigits_tb_Destination] FOREIGN KEY([DestinationID])
REFERENCES [dbo].[tb_Destination] ([DestinationID])
GO
ALTER TABLE [dbo].[tb_DialedDigits] CHECK CONSTRAINT [FK_tb_DialedDigits_tb_Destination]
GO
ALTER TABLE [dbo].[tb_DialedDigits]  WITH CHECK ADD  CONSTRAINT [FK_tb_DialedDigits_tb_NumberPlan] FOREIGN KEY([NumberPlanID])
REFERENCES [dbo].[tb_NumberPlan] ([NumberPlanID])
GO
ALTER TABLE [dbo].[tb_DialedDigits] CHECK CONSTRAINT [FK_tb_DialedDigits_tb_NumberPlan]
GO
