USE [UC_Operations]
GO
/****** Object:  Table [dbo].[tb_Parameter]    Script Date: 5/2/2020 6:24:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_Parameter](
	[ParameterID] [int] IDENTITY(1,1) NOT NULL,
	[ParameterTypeID] [int] NOT NULL,
	[ParameterName] [varchar](100) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NULL,
 CONSTRAINT [PK_tb_Parameter] PRIMARY KEY CLUSTERED 
(
	[ParameterID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [uc_ParameterName] UNIQUE NONCLUSTERED 
(
	[ParameterName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_Parameter]  WITH CHECK ADD  CONSTRAINT [FK_tb_Parameter_tb_ParameterType] FOREIGN KEY([ParameterTypeID])
REFERENCES [dbo].[Tb_ParameterType] ([ParameterTypeID])
GO
ALTER TABLE [dbo].[tb_Parameter] CHECK CONSTRAINT [FK_tb_Parameter_tb_ParameterType]
GO
