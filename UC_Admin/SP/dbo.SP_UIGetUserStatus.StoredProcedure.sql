USE [UC_Admin]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetUserStatus]    Script Date: 5/2/2020 5:59:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_UIGetUserStatus]
--With Encryption
As

Select 0 as ID , 'All' as Name
union
Select UserStatusID as ID , UserStatus as Name
from tb_UserStatus

Return
GO
