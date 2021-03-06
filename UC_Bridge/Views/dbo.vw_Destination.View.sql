USE [UC_Bridge]
GO
/****** Object:  View [dbo].[vw_Destination]    Script Date: 5/2/2020 6:44:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE     VIEW [dbo].[vw_Destination]
--With Encryption
AS

select dest.DestinationID , dest.Destination , DestinationAbbrv , DestinationTypeID , 
       dest.CountryID ,dest.numberplanID , dest.BeginDate , dest.EndDate
from Referenceserver.UC_Reference.dbo.tb_Destination dest
inner join Referenceserver.UC_Reference.dbo.tb_NumberPlan np on dest.numberplanID = np.numberplanid
where np.numberplantypeID = 2 -- Vendor Number Plan
and dest.Flag & 1 <> 1
and np.Flag & 1 <> 1
	


GO
