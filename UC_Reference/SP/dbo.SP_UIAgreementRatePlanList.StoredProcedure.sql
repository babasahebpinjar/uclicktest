USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIAgreementRatePlanList]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIAgreementRatePlanList]
(
	@AgreementID int = NULL,
	@SelectDate datetime
)
As

Select tbl1.RatePlanID , tbl1.RatePlan , tbl2.RatePlanGroupID , tbl2.RatePlanGroup
from tb_RatePlan tbl1
inner join tb_RatePlanGroup tbl2 on tbl1.RatePlanGroupID = tbl2.RatePlanGroupID
where AgreementID = isnull(@AgreementID , AgreementID)
and tbl1.flag & 1 <> 1 -- Dont display hidden RatePlans
and @SelectDate between BeginDate and isnull(Enddate , @SelectDate)
order by BeginDate ,RatePlan
GO
