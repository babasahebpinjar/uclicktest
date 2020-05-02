USE [UC_Bridge]
GO
/****** Object:  View [dbo].[vw_Numberplan]    Script Date: 5/2/2020 6:44:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE     VIEW [dbo].[vw_Numberplan]
--With Encryption 
AS

select NumberPlanID , NumberPlan , NumberPlanAbbrv , ExternalCode
from ReferenceServer.uc_Reference.dbo.tb_numberplan
where numberplantypeID = 2 -- Vendor Number Plan
and flag & 1 <> 1

GO
