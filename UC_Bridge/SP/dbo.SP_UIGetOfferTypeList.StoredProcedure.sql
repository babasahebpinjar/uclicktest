USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetOfferTypeList]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetOfferTypeList] 
--With Encryption
As


select ID as OfferTypeID , Code as OfferType
from tblOfferType
GO
