USE [UC_Reference]
GO
/****** Object:  Table [dbo].[tb_Person]    Script Date: 5/2/2020 6:27:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tb_Person](
	[PersonID] [int] IDENTITY(1,1) NOT NULL,
	[PersonTypeID] [int] NOT NULL,
	[LastName] [varchar](50) NOT NULL,
	[MI] [varchar](1) NULL,
	[FirstName] [varchar](50) NOT NULL,
	[Address1] [varchar](250) NULL,
	[Address2] [varchar](250) NULL,
	[City] [varchar](30) NULL,
	[State] [varchar](32) NULL,
	[Zip] [varchar](16) NULL,
	[Country] [varchar](50) NULL,
	[WorkPhone] [varchar](30) NULL,
	[HomePhone] [varchar](30) NULL,
	[CellPhone] [varchar](30) NULL,
	[Pager] [varchar](30) NULL,
	[WorkFax] [varchar](30) NULL,
	[HomeFax] [varchar](30) NULL,
	[EmailAddress] [varchar](50) NOT NULL,
	[Salutation] [varchar](16) NOT NULL,
	[Company] [varchar](150) NULL,
	[Title] [varchar](50) NULL,
	[CreatedDate] [datetime] NOT NULL,
	[CreatedByID] [int] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[ModifiedByID] [int] NOT NULL,
	[Flag] [int] NOT NULL,
 CONSTRAINT [PK_tb_Person] PRIMARY KEY CLUSTERED 
(
	[PersonID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UC_tb_Person] UNIQUE NONCLUSTERED 
(
	[LastName] ASC,
	[FirstName] ASC,
	[EmailAddress] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tb_Person] ADD  CONSTRAINT [DF_tb_Person_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[tb_Person] ADD  CONSTRAINT [DF_tb_Person_ModifiedDate]  DEFAULT (getdate()) FOR [ModifiedDate]
GO
ALTER TABLE [dbo].[tb_Person] ADD  CONSTRAINT [DF_tb_Person_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[tb_Person]  WITH CHECK ADD  CONSTRAINT [FK_tb_Person_tb_PersonType] FOREIGN KEY([PersonTypeID])
REFERENCES [dbo].[tb_PersonType] ([PersonTypeID])
GO
ALTER TABLE [dbo].[tb_Person] CHECK CONSTRAINT [FK_tb_Person_tb_PersonType]
GO
