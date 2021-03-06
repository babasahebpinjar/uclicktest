USE [UC_Report]
GO
/****** Object:  Table [dbo].[tb_MasterlogExtractParamList]    Script Date: 5/2/2020 6:38:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_MasterlogExtractParamList](
	[MasterlogExtractParamListID] [int] IDENTITY(1,1) NOT NULL,
	[MasterlogExtractID] [int] NOT NULL,
	[CallID] [varchar](2000) NULL,
	[CallingNumber] [varchar](2000) NULL,
	[CalledNumber] [varchar](2000) NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
 CONSTRAINT [PK_tb_MasterlogExtractParamList] PRIMARY KEY CLUSTERED 
(
	[MasterlogExtractParamListID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_MasterlogExtractParamList] UNIQUE NONCLUSTERED 
(
	[MasterlogExtractID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_MasterlogExtractParamList]  WITH CHECK ADD  CONSTRAINT [FK_tb_MasterlogExtractParamList_tb_MasterlogExtract] FOREIGN KEY([MasterlogExtractID])
REFERENCES [dbo].[tb_MasterlogExtract] ([MasterlogExtractId])
GO
ALTER TABLE [dbo].[tb_MasterlogExtractParamList] CHECK CONSTRAINT [FK_tb_MasterlogExtractParamList_tb_MasterlogExtract]
GO
