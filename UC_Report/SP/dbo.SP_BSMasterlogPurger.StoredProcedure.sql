USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMasterlogPurger]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[SP_BSMasterlogPurger]
AS

Declare @command varchar(2000)

set @command = 'C:\\Users\\uclick\\AppData\\Local\\Programs\\Python\\Python36\\python.exe G:\\Uclick_Product_Suite\\MLog\\Code\\purging.py'



Declare @ErrorDescription varchar(2000),
        @ResultFlag int

set @ErrorDescription = NULL
set @ResultFlag = 0

Exec master..xp_cmdshell @command

Return 0
GO
