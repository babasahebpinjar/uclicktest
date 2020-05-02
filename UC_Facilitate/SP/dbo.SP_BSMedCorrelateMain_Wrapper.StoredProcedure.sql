USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMedCorrelateMain_Wrapper]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_BSMedCorrelateMain_Wrapper]
AS

Declare @ErrorDescription varchar(2000),
        @ResultFlag int

set @ErrorDescription = NULL
set @ResultFlag = 0

Exec SP_BSMedCorrelateMain @ErrorDescription Output , @ResultFlag Output

Return 0
GO
