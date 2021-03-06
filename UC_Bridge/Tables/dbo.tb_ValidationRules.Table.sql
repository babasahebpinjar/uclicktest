USE [UC_Bridge]
GO
/****** Object:  Table [dbo].[tb_ValidationRules]    Script Date: 5/2/2020 6:44:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_ValidationRules](
	[ValidationRuleID] [int] IDENTITY(1,1) NOT NULL,
	[RuleName] [varchar](1000) NOT NULL,
	[ReferenceID] [int] NOT NULL,
	[ruleSequence] [int] NOT NULL,
	[ActionScript] [varchar](2000) NOT NULL,
	[validationstatusid] [int] NOT NULL,
 CONSTRAINT [PK_tb_ValidationRules] PRIMARY KEY CLUSTERED 
(
	[ValidationRuleID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [uc_Referenceid_RuleSequence] UNIQUE NONCLUSTERED 
(
	[ReferenceID] ASC,
	[ruleSequence] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_ValidationRules] ADD  DEFAULT ((1)) FOR [validationstatusid]
GO
