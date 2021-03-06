USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_RatePlanGroup]    Script Date: 5/2/2020 6:27:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_RatePlanGroup](
	[RatePlanGroupID] [int] IDENTITY(1,1) NOT NULL,
	[RatePlanGroup] [varchar](60) NOT NULL,
	[RatePlanGroupAbbrv] [varchar](20) NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_RatePlanGroup] PRIMARY KEY CLUSTERED 
(
	[RatePlanGroupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_RatePlanGroup] UNIQUE NONCLUSTERED 
(
	[RatePlanGroup] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_RatePlanGroup] ADD  CONSTRAINT [DF_tb_RatePlanGroup_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_RatePlanGroup] ADD  CONSTRAINT [DF_tb_RatePlanGroup_Flag]  DEFAULT ((0)) FOR [Flag]
GO
