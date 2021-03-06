USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_Company]    Script Date: 5/2/2020 6:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_Company](
	[CompanyID] [int] IDENTITY(1,1) NOT NULL,
	[Company] [varchar](60) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_Company] PRIMARY KEY NONCLUSTERED 
(
	[CompanyID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_Company] UNIQUE NONCLUSTERED 
(
	[Company] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_Company] ADD  CONSTRAINT [DF__tb_Company__Modif__08B54D69]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_Company] ADD  CONSTRAINT [DF__tb_Company__Flag__2EDAF651]  DEFAULT ((0)) FOR [Flag]
GO
