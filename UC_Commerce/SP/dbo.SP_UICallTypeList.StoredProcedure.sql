USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICallTypeList]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UICallTypeList]
As

Select CallTypeID as ID , CallType as Name
from UC_Reference.dbo.tb_CallType
where flag & 1 <> 1
and UseFlag & 64 = 64 --- Use Call Type for rating
order by calltype
GO
