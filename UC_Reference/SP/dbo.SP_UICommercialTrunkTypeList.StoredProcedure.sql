USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICommercialTrunkTypeList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UICommercialTrunkTypeList]
As

select TrunkTypeID as ID , TrunkType as Name
from tb_TrunkType
where flag & 1 <> 1
and trunktypeid = 9
GO
