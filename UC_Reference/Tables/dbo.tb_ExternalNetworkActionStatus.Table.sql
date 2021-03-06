USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_ExternalNetworkActionStatus]    Script Date: 5/2/2020 6:27:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_ExternalNetworkActionStatus](
	[ExternalNetworkActionStatusID] [int] NOT NULL,
	[ExternalNetworkActionStatus] [varchar](100) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
 CONSTRAINT [PK_tb_ExternalNetworkActionStatus] PRIMARY KEY CLUSTERED 
(
	[ExternalNetworkActionStatusID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_ExternalNetworkActionStatus] UNIQUE NONCLUSTERED 
(
	[ExternalNetworkActionStatus] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
