USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetOfferStatusList]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetOfferStatusList]
--With Encryption
As

select offerStatusID , OfferStatus
from
(
	select 0 as offerStatusID, 'All' as OfferStatus
	union
	Select OfferstatusID, OfferStatus 
	from  tb_OfferStatus 
) as tbl1
order by offerstatus
GO
