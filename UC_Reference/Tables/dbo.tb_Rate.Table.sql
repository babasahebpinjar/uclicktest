USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_Rate]    Script Date: 5/2/2020 6:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_Rate](
	[RateID] [int] IDENTITY(1,1) NOT NULL,
	[RatePlanID] [int] NOT NULL,
	[DestinationID] [int] NOT NULL,
	[CallTypeID] [int] NOT NULL,
	[RatingMethodID] [int] NOT NULL,
	[BeginDate] [datetime] NOT NULL,
	[EndDate] [datetime] NULL,
	[ModifiedDate] [datetime] NULL,
	[ModifiedByID] [int] NULL,
	[Flag] [int] NULL,
 CONSTRAINT [PK_tb_Rate] PRIMARY KEY CLUSTERED 
(
	[RateID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_Rate] ADD  CONSTRAINT [DF_tb_Rate_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_Rate] ADD  CONSTRAINT [DF_tb_Rate_ModifiedByID]  DEFAULT ((1)) FOR [ModifiedByID]
GO
ALTER TABLE [dbo].[tb_Rate] ADD  CONSTRAINT [DF_tb_Rate_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_Rate]  WITH CHECK ADD  CONSTRAINT [FK_tb_Rate_tb_RatePlan] FOREIGN KEY([RatePlanID])
REFERENCES [dbo].[tb_RatePlan] ([RatePlanID])
GO
ALTER TABLE [dbo].[tb_Rate] CHECK CONSTRAINT [FK_tb_Rate_tb_RatePlan]
GO
ALTER TABLE [dbo].[tb_Rate]  WITH CHECK ADD  CONSTRAINT [FK_tb_Rate_tb_RatingMethod] FOREIGN KEY([RatingMethodID])
REFERENCES [dbo].[tb_RatingMethod] ([RatingMethodID])
GO
ALTER TABLE [dbo].[tb_Rate] CHECK CONSTRAINT [FK_tb_Rate_tb_RatingMethod]
GO
