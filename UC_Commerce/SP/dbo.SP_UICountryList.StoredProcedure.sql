USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICountryList]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UICountryList]
(
    @Country varchar(60) = NULL
)
As


Exec UC_REference.dbo.SP_UICountryList @Country

Return
GO
