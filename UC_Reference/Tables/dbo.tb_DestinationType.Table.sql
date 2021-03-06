USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_DestinationType]    Script Date: 5/2/2020 6:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_DestinationType](
	[DestinationTypeID] [int] NOT NULL,
	[DestinationType] [char](60) NOT NULL,
	[DestinationTypeAbbrv] [char](16) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_DestinationType] PRIMARY KEY CLUSTERED 
(
	[DestinationTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_DestinationType] UNIQUE NONCLUSTERED 
(
	[DestinationType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_DestinationType] ADD  CONSTRAINT [DF_tb_DestinationType_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_DestinationType] ADD  CONSTRAINT [DF_tb_DestinationType_Flag]  DEFAULT ((0)) FOR [Flag]
GO
