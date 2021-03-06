USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_CustomSwitchTrunkTranslation]    Script Date: 5/2/2020 6:27:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_CustomSwitchTrunkTranslation](
	[TrunkGroupID] [varchar](60) NOT NULL,
	[TrunkGroupName] [varchar](500) NOT NULL,
	[TrunkName] [varchar](60) NOT NULL,
	[PrefixCode] [varchar](10) NULL,
 CONSTRAINT [PK_tb_CustomSwitchTrunkTranslation] PRIMARY KEY CLUSTERED 
(
	[TrunkGroupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
