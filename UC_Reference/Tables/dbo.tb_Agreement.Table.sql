USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_Agreement]    Script Date: 5/2/2020 6:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_Agreement](
	[AgreementID] [int] IDENTITY(1,1) NOT NULL,
	[Agreement] [varchar](60) NOT NULL,
	[AgreementAbbrv] [varchar](20) NOT NULL,
	[AccountID] [int] NOT NULL,
	[BeginDate] [datetime] NOT NULL,
	[EndDate] [datetime] NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_Agreement] PRIMARY KEY CLUSTERED 
(
	[AgreementID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_Agreement] UNIQUE NONCLUSTERED 
(
	[Agreement] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_Agreement] ADD  CONSTRAINT [DF_tb_Agreement_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_Agreement] ADD  CONSTRAINT [DF_tb_Agreement_ModifiedByID]  DEFAULT ((1)) FOR [ModifiedByID]
GO
ALTER TABLE [dbo].[tb_Agreement] ADD  CONSTRAINT [DF_tb_Agreement_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_Agreement]  WITH CHECK ADD  CONSTRAINT [FK_tb_Agreement_tb_Account] FOREIGN KEY([AccountID])
REFERENCES [dbo].[tb_Account] ([AccountID])
GO
ALTER TABLE [dbo].[tb_Agreement] CHECK CONSTRAINT [FK_tb_Agreement_tb_Account]
GO
