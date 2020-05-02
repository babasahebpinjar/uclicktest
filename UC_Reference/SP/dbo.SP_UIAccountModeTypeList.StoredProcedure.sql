USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIAccountModeTypeList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UIAccountModeTypeList]
As

Select AccountModeTypeID as ID , AccountModeType as Name
from tb_AccountModeType
where flag & 1 <> 1
order by AccountModeType
GO
