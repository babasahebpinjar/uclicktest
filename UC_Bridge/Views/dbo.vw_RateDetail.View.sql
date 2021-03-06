USE [UC_Bridge]
GO
/****** Object:  View [dbo].[vw_RateDetail]    Script Date: 5/2/2020 6:44:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE     VIEW [dbo].[vw_RateDetail]
--With Encryption
AS


select rdt.*
from Referenceserver.UC_Reference.dbo.tb_RateDetail rdt
inner join  Referenceserver.UC_Reference.dbo.tb_Rate rt on rdt.rateID = rt.RateID
inner join Referenceserver.UC_Reference.dbo.tb_RatePlan rp on rt.RatePlanID = rp.RatePlanID
where rp.ProductCataLogID = -4 -- Vendor Destination Rating
and rt.flag & 1 <> 1 
	


GO
