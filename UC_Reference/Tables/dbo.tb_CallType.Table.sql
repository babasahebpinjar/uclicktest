USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_CallType]    Script Date: 5/2/2020 6:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_CallType](
	[CallTypeID] [int] IDENTITY(1,1) NOT NULL,
	[CallType] [varchar](60) NOT NULL,
	[CallTypeAbbrv] [varchar](20) NOT NULL,
	[ChargeBasisID] [int] NOT NULL,
	[UseFlag] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_CallType] PRIMARY KEY CLUSTERED 
(
	[CallTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_CallType] UNIQUE NONCLUSTERED 
(
	[CallType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_CallType] ADD  CONSTRAINT [DF_tb_CallType_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_CallType] ADD  CONSTRAINT [DF_tb_CallType_ModifiedByID]  DEFAULT ((-1)) FOR [ModifiedByID]
GO
ALTER TABLE [dbo].[tb_CallType] ADD  CONSTRAINT [DF_tb_CallType_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_CallType]  WITH CHECK ADD  CONSTRAINT [FK_tb_CallType_tb_ChargeBasis] FOREIGN KEY([ChargeBasisID])
REFERENCES [dbo].[tb_ChargeBasis] ([ChargeBasisID])
GO
ALTER TABLE [dbo].[tb_CallType] CHECK CONSTRAINT [FK_tb_CallType_tb_ChargeBasis]
GO
