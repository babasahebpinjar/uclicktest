USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_ChargeBasis]    Script Date: 5/2/2020 6:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_ChargeBasis](
	[ChargeBasisID] [int] IDENTITY(1,1) NOT NULL,
	[ChargeBasis] [varchar](60) NOT NULL,
	[ChargeBasisAbbrv] [varchar](20) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_ChargeBasis] PRIMARY KEY CLUSTERED 
(
	[ChargeBasisID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_ChargeBasis] UNIQUE NONCLUSTERED 
(
	[ChargeBasis] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_ChargeBasis] ADD  CONSTRAINT [DF_tb_ChargeBasis_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_ChargeBasis] ADD  CONSTRAINT [DF_tb_ChargeBasis_ModifiedByID]  DEFAULT ((-1)) FOR [ModifiedByID]
GO
ALTER TABLE [dbo].[tb_ChargeBasis] ADD  CONSTRAINT [DF_tb_ChargeBasis_Flag]  DEFAULT ((0)) FOR [Flag]
GO
