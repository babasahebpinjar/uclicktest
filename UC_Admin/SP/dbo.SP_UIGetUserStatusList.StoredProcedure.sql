USE [UC_Admin]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetUserStatusList]    Script Date: 5/2/2020 5:59:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_UIGetUserStatusList]
--With Encryption 
As

Select UserStatusID as ID, UserStatus as Name
from tb_UserStatus

Return
GO
