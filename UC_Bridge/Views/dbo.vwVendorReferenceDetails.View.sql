USE [UC_Bridge]
GO
/****** Object:  View [dbo].[vwVendorReferenceDetails]    Script Date: 5/2/2020 6:44:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[vwVendorReferenceDetails]
As
SELECT Account As Source, * FROM TB_VendorReferenceDetails

GO
