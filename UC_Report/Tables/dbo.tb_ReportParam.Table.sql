USE [UC_Report]
GO
/****** Object:  Table [dbo].[tb_ReportParam]    Script Date: 5/2/2020 6:38:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_ReportParam](
	[ReportParamID] [int] IDENTITY(1,1) NOT NULL,
	[ReportID] [int] NOT NULL,
	[ParamType] [varchar](60) NOT NULL,
	[ParameterID] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_ReportParam] PRIMARY KEY CLUSTERED 
(
	[ReportParamID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_ReportParam] UNIQUE NONCLUSTERED 
(
	[ReportID] ASC,
	[ParamType] ASC,
	[ParameterID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_ReportParam]  WITH CHECK ADD  CONSTRAINT [FK_tb_ReportParam_tb_Report] FOREIGN KEY([ReportID])
REFERENCES [dbo].[tb_Report] ([ReportID])
GO
ALTER TABLE [dbo].[tb_ReportParam] CHECK CONSTRAINT [FK_tb_ReportParam_tb_Report]
GO
