USE [UC_Bridge]
GO
/****** Object:  Table [dbo].[tempAuthorizedSender]    Script Date: 5/2/2020 6:44:28 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tempAuthorizedSender](
	[EmailAddress] [varchar](100) NULL,
	[Account] [varchar](60) NULL
) ON [PRIMARY]
GO
