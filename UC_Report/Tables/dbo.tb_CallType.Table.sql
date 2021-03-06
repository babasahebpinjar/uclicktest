USE [UC_Report]
GO
/****** Object:  Table [dbo].[tb_CallType]    Script Date: 5/2/2020 6:38:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_CallType](
	[CallTypeID] [int] NOT NULL,
	[CallType] [varchar](60) NOT NULL,
	[CallTypeAbbrv] [varchar](20) NOT NULL,
	[ChargeBasisID] [int] NOT NULL,
	[UseFlag] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL
) ON [PRIMARY]
GO
