USE [UC_Bridge]
GO
/****** Object:  View [dbo].[vw_Country]    Script Date: 5/2/2020 6:44:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE     VIEW [dbo].[vw_Country]
--With Encryption
AS

Select CountryID , Country , CountryAbbrv , CountryCode
from Referenceserver.uc_Reference.dbo.tb_Country
where CountryID > 0
and flag & 1 <> 1
	

GO
