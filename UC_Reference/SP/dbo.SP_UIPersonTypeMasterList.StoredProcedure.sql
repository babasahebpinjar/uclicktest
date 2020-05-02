USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIPersonTypeMasterList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     PROCEDURE [dbo].[SP_UIPersonTypeMasterList]
 AS

select PersonTypeid as ID, PersonType as Name
from
(
	select PersonTypeid , PersonType
	from tb_PersonType
	where flag & 1 <> 1
	union
	select 0 , 'All'
) tbl1
order by 1 desc

Return 0
GO
