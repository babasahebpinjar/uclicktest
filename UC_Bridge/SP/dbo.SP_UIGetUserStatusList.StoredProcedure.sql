USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetUserStatusList]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetUserStatusList]
--With Encryption
As

Select UserStatusID , UserStatus
from tb_UserStatus

Return
GO
