USE [UC_Operations]
GO
/****** Object:  Table [dbo].[tb_ObjectInstance]    Script Date: 5/2/2020 6:24:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_ObjectInstance](
	[ObjectInstanceID] [int] IDENTITY(1,1) NOT NULL,
	[ObjectID] [int] NOT NULL,
	[ObjectInstance] [varchar](200) NOT NULL,
	[StatusID] [int] NOT NULL,
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL,
	[ProcessStartTime] [datetime] NULL,
	[ProcessEndTime] [datetime] NULL,
	[Remarks] [varchar](2000) NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
 CONSTRAINT [PK_tb_ObjectInstance] PRIMARY KEY CLUSTERED 
(
	[ObjectInstanceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [uc_tb_ObjectInstance] UNIQUE NONCLUSTERED 
(
	[ObjectInstance] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_ObjectInstance]  WITH CHECK ADD  CONSTRAINT [FK_tb_ObjectInstance_tb_Object] FOREIGN KEY([ObjectID])
REFERENCES [dbo].[tb_Object] ([ObjectID])
GO
ALTER TABLE [dbo].[tb_ObjectInstance] CHECK CONSTRAINT [FK_tb_ObjectInstance_tb_Object]
GO
