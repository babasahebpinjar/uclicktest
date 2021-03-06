USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetOfferTypeListALL]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetOfferTypeListALL]
--With Encryption
As

select OfferTypeID , OfferType
from
(
	select 0 as OfferTypeID, 'All' as OfferType
	union
	Select ID as OfeerTypeID, Code as OfferStatus 
	from  tbloffertype 
) as tbl1
order by OfferType
GO
