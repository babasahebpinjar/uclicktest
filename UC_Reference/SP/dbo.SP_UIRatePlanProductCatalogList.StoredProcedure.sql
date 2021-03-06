USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRatePlanProductCatalogList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRatePlanProductCatalogList]
(
	@DirectionID int
)
As



if ( @DirectionID = 1 ) --- Inbound
Begin

	Select ProductCatalogID as ID , ProductCatalog as Name
	from tb_ProductCatalog
	where ProductCatalogTypeID in ( -2 , -3 ) -- Hubbing and Aggregate Rating
	and ProductCatalogID <> -4 -- Exclude Vendor
	and flag & 1 <> 1
	order by ProductCatalog

End 

if ( @DirectionID = 2 ) --- Outbound
Begin

	Select ProductCatalogID as ID , ProductCatalog as Name
	from tb_ProductCatalog
	where ProductCatalogTypeID in ( -2 , -3 ) -- Hubbing and Aggregate Rating
	and ProductCatalogID <>  -5 -- Exclude Customer 
	and flag & 1 <> 1
	order by ProductCatalog

End 
GO
