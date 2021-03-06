USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetSettlementForScenario]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetSettlementForScenario]
(
	@RatingScenarioID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ResultFlag = 0
set @ErrorDescription = NULL

if ( @RatingScenarioID is null )
Begin

		set @ErrorDescription = 'ERROR !!! Rating Scenario ID cannot be NULL. Please pass a valid value'
		set @ResultFlag = 1
		Return 1

End

if not exists ( select 1 from tb_RatingScenario where RatingScenarioID = @RatingScenarioID and RatingScenarioTypeID in (-1,-3)  )
Begin

		set @ErrorDescription = 'ERROR !!! Rating Scenario ID does not exist in the system. Please check details'
		set @ResultFlag = 1
		Return 1

End

Select tbl1.RatingSettlementID , 
	   tbl1.TariffTypeID , tbl2.TariffType, 
	   tbl1.RatePlanID , tbl4.RatePlan, Percentage,
       tbl1.ChargeTypeID , tbl3.ChargeType , 
	   tbl1.ModifiedDate , UC_Admin.dbo.FN_GetUserName(tbl1.ModifiedByID) as ModifiedByUser
from tb_RatingSettlement tbl1
inner join tb_Tarifftype tbl2 on tbl1.TariffTypeID = tbl2.TariffTypeID
inner join tb_ChargeType tbl3 on tbl1.ChargeTypeID = tbl3.ChargeTypeID
inner join tb_RatePlan tbl4 on tbl1.RatePlanID = tbl4.RatePlanID
where RatingScenarioID = @RatingScenarioID
GO
