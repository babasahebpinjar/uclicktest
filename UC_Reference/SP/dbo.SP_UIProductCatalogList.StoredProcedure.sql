USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIProductCatalogList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIProductCatalogList]
(
	@ProductCatalogTypeID int = NULL
)
As

Select ProductCatalogID as ID , ProductCatalog as Name
from tb_ProductCatalog
where ProductCatalogTypeID = isnull(@ProductCatalogTypeID , ProductCatalogTypeID)
and flag & 1 <> 1
GO
