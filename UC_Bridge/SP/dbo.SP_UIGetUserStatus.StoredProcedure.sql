USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetUserStatus]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetUserStatus]
--With Encryption
As

Select 0 , 'All'
union
Select UserStatusID , UserStatus
from tb_UserStatus

Return
GO
