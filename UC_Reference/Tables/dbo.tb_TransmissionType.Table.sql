USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_TransmissionType]    Script Date: 5/2/2020 6:27:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_TransmissionType](
	[TransmissionTypeID] [int] IDENTITY(1,1) NOT NULL,
	[TransmissionType] [varchar](60) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_TransmissionType] PRIMARY KEY CLUSTERED 
(
	[TransmissionTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_TransmissionType] UNIQUE NONCLUSTERED 
(
	[TransmissionType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_TransmissionType] ADD  CONSTRAINT [DF_tb_TransmissionType_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_TransmissionType] ADD  CONSTRAINT [DF_tb_TransmissionType_ModifiedByID]  DEFAULT ((-1)) FOR [ModifiedByID]
GO
ALTER TABLE [dbo].[tb_TransmissionType] ADD  CONSTRAINT [DF_tb_TransmissionType_Flag]  DEFAULT ((0)) FOR [Flag]
GO
