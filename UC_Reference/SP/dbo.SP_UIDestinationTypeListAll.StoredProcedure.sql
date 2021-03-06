USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIDestinationTypeListAll]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIDestinationTypeListAll]
As

select ID , Name
from
(
	Select 0 as ID , 'All' as Name
	union
	Select DestinationTypeID as ID , DestinationType as Name
	from tb_DestinationType
	where flag & 1 <> 1
) as tbl1
order by Name
GO
