USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetIncomingEmailStatus]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetIncomingEmailStatus]
--With Encryption
As

Select 0 , 'All'
union
Select id, description
from tblStatusMaster
where id in (1,2,3,4,5,6)

Return
GO
