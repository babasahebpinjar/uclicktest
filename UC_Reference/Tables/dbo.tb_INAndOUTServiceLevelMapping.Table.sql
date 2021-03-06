USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_INAndOUTServiceLevelMapping]    Script Date: 5/2/2020 6:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_INAndOUTServiceLevelMapping](
	[INAndOUTServiceLevelMappingID] [int] IDENTITY(1,1) NOT NULL,
	[INServiceLevelID] [int] NOT NULL,
	[OUTServiceLevelID] [int] NOT NULL,
	[BeginDate] [datetime] NOT NULL,
	[EndDate] [datetime] NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_INAndOUTServiceLevelMapping] PRIMARY KEY CLUSTERED 
(
	[INAndOUTServiceLevelMappingID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_INAndOUTServiceLevelMapping] UNIQUE NONCLUSTERED 
(
	[INServiceLevelID] ASC,
	[BeginDate] ASC,
	[EndDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_INAndOUTServiceLevelMapping] ADD  CONSTRAINT [DF_tb_INAndOUTServiceLevelMapping_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_INAndOUTServiceLevelMapping] ADD  CONSTRAINT [DF_tb_INAndOUTServiceLevelMapping_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_INAndOUTServiceLevelMapping]  WITH CHECK ADD  CONSTRAINT [FK_tb_INAndOUTServiceLevelMapping_tb_ServiceLevel_1] FOREIGN KEY([INServiceLevelID])
REFERENCES [dbo].[tb_ServiceLevel] ([ServiceLevelID])
GO
ALTER TABLE [dbo].[tb_INAndOUTServiceLevelMapping] CHECK CONSTRAINT [FK_tb_INAndOUTServiceLevelMapping_tb_ServiceLevel_1]
GO
ALTER TABLE [dbo].[tb_INAndOUTServiceLevelMapping]  WITH CHECK ADD  CONSTRAINT [FK_tb_INAndOUTServiceLevelMapping_tb_ServiceLevel_2] FOREIGN KEY([OUTServiceLevelID])
REFERENCES [dbo].[tb_ServiceLevel] ([ServiceLevelID])
GO
ALTER TABLE [dbo].[tb_INAndOUTServiceLevelMapping] CHECK CONSTRAINT [FK_tb_INAndOUTServiceLevelMapping_tb_ServiceLevel_2]
GO
