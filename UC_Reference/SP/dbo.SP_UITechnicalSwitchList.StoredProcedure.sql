USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UITechnicalSwitchList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create Procedure [dbo].[SP_UITechnicalSwitchList] As


Select switchID as ID , Switch as Name
from tb_switch
where switchtypeid <> 5
and flag & 1 <> 1
GO
