USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICountrytypeList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     PROCEDURE [dbo].[SP_UICountrytypeList]
 AS

select countrytypeid as ID , countrytype as Name
from tb_countrytype
where flag&1 <> 1
order by 1 desc

Return 0
















GO
