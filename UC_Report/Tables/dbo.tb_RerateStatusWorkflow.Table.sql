USE [UC_Report]
GO
/****** Object:  Table [dbo].[tb_RerateStatusWorkflow]    Script Date: 5/2/2020 6:38:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_RerateStatusWorkflow](
	[RerateStatusWorkflowID] [int] NOT NULL,
	[FromRerateStatusID] [int] NOT NULL,
	[ToRerateStatusID] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_RerateStatusWorkflow] PRIMARY KEY CLUSTERED 
(
	[RerateStatusWorkflowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_RerateStatusWorkflow] UNIQUE NONCLUSTERED 
(
	[FromRerateStatusID] ASC,
	[ToRerateStatusID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
