USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetVendorOfferFormatList]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetVendorOfferFormatList]  
--With Encryption
As

select distinct VendorOfferFormat
from tb_VOT
order by 1
GO
