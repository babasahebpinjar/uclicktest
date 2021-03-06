USE [UC_Bridge]
GO
/****** Object:  Table [dbo].[tb_ValidationStatus]    Script Date: 5/2/2020 6:44:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_ValidationStatus](
	[ValidationStatusID] [int] IDENTITY(1,1) NOT NULL,
	[ValidationStatus] [varchar](50) NOT NULL,
 CONSTRAINT [PK_tb_ValidationStatus] PRIMARY KEY CLUSTERED 
(
	[ValidationStatusID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [uc_ValidationStatus] UNIQUE NONCLUSTERED 
(
	[ValidationStatus] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
