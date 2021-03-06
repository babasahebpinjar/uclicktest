USE [UC_Operations]
GO
/****** Object:  Table [dbo].[tb_PrepaidLastRefreshForCallDate]    Script Date: 5/2/2020 6:24:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_PrepaidLastRefreshForCallDate](
	[CallDate] [date] NOT NULL,
	[LastRefreshDate] [datetime] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
 CONSTRAINT [UC_tb_PrepaidLastRefreshForCallDate] UNIQUE NONCLUSTERED 
(
	[CallDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
