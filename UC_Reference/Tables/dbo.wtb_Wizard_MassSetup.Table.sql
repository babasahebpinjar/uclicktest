USE [UC_Reference]
GO
/****** Object:  Table [dbo].[wtb_Wizard_MassSetup]    Script Date: 5/2/2020 6:27:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[wtb_Wizard_MassSetup](
	[WizardID] [int] IDENTITY(1,1) NOT NULL,
	[SessionID] [varchar](36) NOT NULL,
	[WizardName] [varchar](256) NOT NULL,
	[WizardStep] [int] NOT NULL,
	[UserID] [int] NOT NULL,
	[VariableName] [varchar](200) NOT NULL,
	[VariableDataType] [varchar](200) NULL,
	[IsMultiRecord] [int] NULL,
	[VariableValue] [varchar](256) NULL,
	[Attribute1] [varchar](256) NULL,
	[Attribute2] [varchar](256) NULL,
	[Attribute3] [varchar](256) NULL,
	[Attribute4] [varchar](256) NULL,
	[Attribute5] [varchar](256) NULL,
	[Attribute6] [varchar](256) NULL,
	[Attribute7] [varchar](256) NULL,
	[Attribute8] [varchar](256) NULL,
	[Attribute9] [varchar](256) NULL,
	[Attribute10] [varchar](256) NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_wtb_Wizard_MassSetup] PRIMARY KEY CLUSTERED 
(
	[WizardID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[wtb_Wizard_MassSetup] ADD  CONSTRAINT [DF_Wizard_MassSetup_IsMultiRecord]  DEFAULT ((0)) FOR [IsMultiRecord]
GO
ALTER TABLE [dbo].[wtb_Wizard_MassSetup] ADD  CONSTRAINT [DF_Wizard_MassSetup_Flag]  DEFAULT ((0)) FOR [Flag]
GO
