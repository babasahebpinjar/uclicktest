USE [UC_Bridge]
GO
/****** Object:  View [dbo].[vw_DialedDigits]    Script Date: 5/2/2020 6:44:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE     VIEW [dbo].[vw_DialedDigits]
--With Encryption
AS

select dd.DialedDigitsID , dd.DialedDigits , dd.NumberPlanID , dd.DestinationID,
       dd.IntIndicator , dd.BeginDate , dd.EndDate
from Referenceserver.UC_Reference.dbo.tb_DialedDigits dd
inner join Referenceserver.UC_Reference.dbo.tb_NumberPlan np on dd.numberplanID = np.numberplanid
where np.numberplantypeID = 2 -- Vendor Number Plan
and dd.Flag & 1 <> 1
and np.Flag & 1 <> 1
	


GO
