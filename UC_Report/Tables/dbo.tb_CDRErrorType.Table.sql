USE [UC_Report]
GO
/****** Object:  Table [dbo].[tb_CDRErrorType]    Script Date: 5/2/2020 6:38:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_CDRErrorType](
	[CDRErrorTypeID] [int] NOT NULL,
	[CDRErrorType] [varchar](100) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_CDRErrorType] PRIMARY KEY CLUSTERED 
(
	[CDRErrorTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_CDRErrorType] UNIQUE NONCLUSTERED 
(
	[CDRErrorType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_CDRErrorType] ADD  CONSTRAINT [DF_tb_CDRErrorType_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_CDRErrorType] ADD  CONSTRAINT [DF_tb_CDRErrorType_Flag]  DEFAULT ((0)) FOR [Flag]
GO
