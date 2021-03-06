USE [UC_Operations]
GO
/****** Object:  Table [dbo].[tb_ObjectTypeParam]    Script Date: 5/2/2020 6:24:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_ObjectTypeParam](
	[ObjectTypeParamID] [int] IDENTITY(1,1) NOT NULL,
	[ObjectTypeID] [int] NOT NULL,
	[ParameterID] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NULL,
 CONSTRAINT [PK_tb_ObjectTypeParam] PRIMARY KEY CLUSTERED 
(
	[ObjectTypeParamID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [uc_ObjectTypeParam] UNIQUE NONCLUSTERED 
(
	[ObjectTypeID] ASC,
	[ParameterID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_ObjectTypeParam]  WITH CHECK ADD  CONSTRAINT [FK_tb_ObjectTypeParam_tb_ObjectType] FOREIGN KEY([ObjectTypeID])
REFERENCES [dbo].[tb_ObjectType] ([ObjectTypeID])
GO
ALTER TABLE [dbo].[tb_ObjectTypeParam] CHECK CONSTRAINT [FK_tb_ObjectTypeParam_tb_ObjectType]
GO
ALTER TABLE [dbo].[tb_ObjectTypeParam]  WITH CHECK ADD  CONSTRAINT [FK_tb_ObjectTypeParam_tb_Parameter] FOREIGN KEY([ParameterID])
REFERENCES [dbo].[tb_Parameter] ([ParameterID])
GO
ALTER TABLE [dbo].[tb_ObjectTypeParam] CHECK CONSTRAINT [FK_tb_ObjectTypeParam_tb_Parameter]
GO
