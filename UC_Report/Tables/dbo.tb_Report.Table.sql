USE [UC_Report]
GO
/****** Object:  Table [dbo].[tb_Report]    Script Date: 5/2/2020 6:38:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_Report](
	[ReportID] [int] NOT NULL,
	[ReportName] [varchar](100) NOT NULL,
	[ReportCategoryID] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_Report] PRIMARY KEY CLUSTERED 
(
	[ReportID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_Report] UNIQUE NONCLUSTERED 
(
	[ReportName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_Report]  WITH CHECK ADD  CONSTRAINT [FK_tb_Report_tb_ReportCategory] FOREIGN KEY([ReportCategoryID])
REFERENCES [dbo].[tb_ReportCategory] ([ReportCategoryID])
GO
ALTER TABLE [dbo].[tb_Report] CHECK CONSTRAINT [FK_tb_Report_tb_ReportCategory]
GO
