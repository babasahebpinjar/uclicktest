USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICommercialSwitchMasterList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UICommercialSwitchMasterList] As

select ID , Name
from
(
	Select switchID as ID , Switch as Name
	from tb_switch
	where switchtypeid = 5
	and flag & 1 <> 1
	union 
	Select 0 as ID , 'All' as Name
) tbl1
order by ID
GO
