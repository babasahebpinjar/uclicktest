USE [UC_Bridge]
GO
/****** Object:  View [dbo].[vw_OfferTemplate]    Script Date: 5/2/2020 6:44:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE     VIEW [dbo].[vw_OfferTemplate]
--With Encryption
AS

Select OfferTemplateID , OfferTemplateName
from Temp_Offertemplate
	
GO
