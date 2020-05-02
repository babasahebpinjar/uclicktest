USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIActiveStatusMasterList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE     PROCEDURE [dbo].[SP_UIActiveStatusMasterList]
 AS

select ActiveStatusid as ID, ActiveStatus as Name
from
(
	select ActiveStatusid , ActiveStatus
	from tb_ActiveStatus
	where flag&1 <> 1
	union
	select 0 , 'All'
) tbl1
order by 1

Return 0
GO
