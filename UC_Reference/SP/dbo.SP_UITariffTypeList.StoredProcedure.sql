USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UITariffTypeList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UITariffTypeList]
As

Select TariffTypeID as ID , TariffType as Name
from tb_TariffType
where flag & 1 <> 1
GO
