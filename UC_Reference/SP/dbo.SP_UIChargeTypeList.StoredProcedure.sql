USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIChargeTypeList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UIChargeTypeList]
As

Select ChargeTypeID as ID , ChargeType as Name
from tb_ChargeType
where flag & 1 <> 1
order by chargetype
GO
