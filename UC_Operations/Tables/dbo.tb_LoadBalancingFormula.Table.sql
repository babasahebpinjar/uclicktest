USE [UC_Operations]
GO
/****** Object:  Table [dbo].[tb_LoadBalancingFormula]    Script Date: 5/2/2020 6:24:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_LoadBalancingFormula](
	[LoadBalancingFormulaID] [int] NOT NULL,
	[LoadBalancingFormula] [varchar](500) NOT NULL,
	[NumberOfCDRInstances] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
 CONSTRAINT [PK_tb_LoadBalancingFormula] PRIMARY KEY CLUSTERED 
(
	[LoadBalancingFormulaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_LoadBalancingFormula] UNIQUE NONCLUSTERED 
(
	[LoadBalancingFormula] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_LoadBalancingFormula] ADD  DEFAULT ((1)) FOR [LoadBalancingFormulaID]
GO
ALTER TABLE [dbo].[tb_LoadBalancingFormula]  WITH CHECK ADD  CONSTRAINT [LoadBalancingFormula_OnlyOneRow] CHECK  (([LoadBalancingFormulaID]=(1)))
GO
ALTER TABLE [dbo].[tb_LoadBalancingFormula] CHECK CONSTRAINT [LoadBalancingFormula_OnlyOneRow]
GO
