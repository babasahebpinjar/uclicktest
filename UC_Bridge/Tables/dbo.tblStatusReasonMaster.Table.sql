USE [UC_Bridge]
GO
/****** Object:  Table [dbo].[tblStatusReasonMaster]    Script Date: 5/2/2020 6:44:28 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblStatusReasonMaster](
	[Code] [nvarchar](5) NOT NULL,
	[ClientID] [int] NOT NULL,
	[Description] [nvarchar](225) NULL,
 CONSTRAINT [PK_tblStatusReasonMaster] PRIMARY KEY CLUSTERED 
(
	[Code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
