USE [UC_Bridge]
GO
/****** Object:  View [dbo].[vw_Accounts]    Script Date: 5/2/2020 6:44:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE     VIEW [dbo].[vw_Accounts]
--With Encryption
AS

Select AccountID , Account , AccountAbbrv
from ReferenceServer.uc_Reference.dbo.tb_account
where accountID > 0
	
GO
