USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_CountryType]    Script Date: 5/2/2020 6:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_CountryType](
	[CountryTypeID] [int] IDENTITY(1,1) NOT NULL,
	[CountryType] [varchar](60) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_countrytype] PRIMARY KEY CLUSTERED 
(
	[CountryTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_countrytype] UNIQUE NONCLUSTERED 
(
	[CountryType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_CountryType] ADD  CONSTRAINT [DF__tbCountry__Modif__0353107C]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_CountryType] ADD  CONSTRAINT [DF__tbCountryT__Flag__053B58EE]  DEFAULT ((0)) FOR [Flag]
GO
