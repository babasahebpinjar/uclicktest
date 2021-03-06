USE [UC_Operations]
GO
/****** Object:  Table [dbo].[tb_ObjectParam]    Script Date: 5/2/2020 6:24:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_ObjectParam](
	[ObjectParamID] [int] IDENTITY(1,1) NOT NULL,
	[ObjectID] [int] NOT NULL,
	[ObjectTypeParamID] [int] NOT NULL,
	[ObjectParamValue] [varchar](1000) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NULL,
 CONSTRAINT [PK_tb_ObjectParam] PRIMARY KEY CLUSTERED 
(
	[ObjectParamID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [uc_ObjectParam] UNIQUE NONCLUSTERED 
(
	[ObjectID] ASC,
	[ObjectTypeParamID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_ObjectParam]  WITH CHECK ADD  CONSTRAINT [FK_tb_ObjectParam_tb_Object] FOREIGN KEY([ObjectID])
REFERENCES [dbo].[tb_Object] ([ObjectID])
GO
ALTER TABLE [dbo].[tb_ObjectParam] CHECK CONSTRAINT [FK_tb_ObjectParam_tb_Object]
GO
ALTER TABLE [dbo].[tb_ObjectParam]  WITH CHECK ADD  CONSTRAINT [FK_tb_ObjectParam_tb_ObjectTypeParam] FOREIGN KEY([ObjectTypeParamID])
REFERENCES [dbo].[tb_ObjectTypeParam] ([ObjectTypeParamID])
GO
ALTER TABLE [dbo].[tb_ObjectParam] CHECK CONSTRAINT [FK_tb_ObjectParam_tb_ObjectTypeParam]
GO
