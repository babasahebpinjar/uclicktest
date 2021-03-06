USE [UC_Report]
GO
/****** Object:  Table [dbo].[tb_Rerate]    Script Date: 5/2/2020 6:38:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_Rerate](
	[RerateID] [int] IDENTITY(1,1) NOT NULL,
	[RerateName] [varchar](500) NOT NULL,
	[UserID] [int] NOT NULL,
	[RerateStatusID] [int] NOT NULL,
	[RerateRequestDate] [datetime] NOT NULL,
	[RerateCompletionDate] [datetime] NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Remarks] [varchar](2000) NULL,
 CONSTRAINT [PK_tb_Rerate] PRIMARY KEY CLUSTERED 
(
	[RerateID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_Rerate] UNIQUE NONCLUSTERED 
(
	[UserID] ASC,
	[RerateName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_Rerate]  WITH CHECK ADD  CONSTRAINT [FK_tb_Rerate_tb_RerateStatus] FOREIGN KEY([RerateStatusID])
REFERENCES [dbo].[tb_RerateStatus] ([RerateStatusID])
GO
ALTER TABLE [dbo].[tb_Rerate] CHECK CONSTRAINT [FK_tb_Rerate_tb_RerateStatus]
GO
