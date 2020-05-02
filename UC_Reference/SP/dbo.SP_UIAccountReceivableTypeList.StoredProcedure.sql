USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIAccountReceivableTypeList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIAccountReceivableTypeList]
As

select AccountReceivableTypeID as ID , AccountReceivableType as Name
from tb_AccountReceivableType
where flag & 1 <> 1
order by AccountReceivableType

return 0
GO
