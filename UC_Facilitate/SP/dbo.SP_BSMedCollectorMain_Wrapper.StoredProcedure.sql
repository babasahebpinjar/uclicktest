USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMedCollectorMain_Wrapper]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create PROCEDURE [dbo].[SP_BSMedCollectorMain_Wrapper]
AS

Declare @ErrorDescription varchar(2000),
        @ResultFlag int

set @ErrorDescription = NULL
set @ResultFlag = 0

Exec SP_BSMedCollectorMain @ErrorDescription Output , @ResultFlag Output

Return 0
GO
