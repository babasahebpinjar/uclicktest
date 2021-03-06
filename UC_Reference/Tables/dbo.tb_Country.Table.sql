USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_Country]    Script Date: 5/2/2020 6:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_Country](
	[CountryID] [int] IDENTITY(1,1) NOT NULL,
	[Country] [varchar](60) NOT NULL,
	[CountryAbbrv] [varchar](20) NOT NULL,
	[CountryCode] [varchar](100) NULL,
	[CountryTypeID] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_Country] PRIMARY KEY CLUSTERED 
(
	[CountryID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_Country] UNIQUE NONCLUSTERED 
(
	[Country] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_Country] ADD  CONSTRAINT [DF_tb_Country_CountryTypeID]  DEFAULT ((1)) FOR [CountryTypeID]
GO
ALTER TABLE [dbo].[tb_Country] ADD  CONSTRAINT [DF_tb_Country_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_Country] ADD  CONSTRAINT [DF_tb_Country_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_Country]  WITH CHECK ADD  CONSTRAINT [FK_tb_Country_tb_CountryType] FOREIGN KEY([CountryTypeID])
REFERENCES [dbo].[tb_CountryType] ([CountryTypeID])
GO
ALTER TABLE [dbo].[tb_Country] CHECK CONSTRAINT [FK_tb_Country_tb_CountryType]
GO
