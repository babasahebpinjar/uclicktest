USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIHubbingScenarioGetDetails]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIHubbingScenarioGetDetails]
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

Declare @ScenarioTypeID int

select @ScenarioTypeID = RatingScenarioTypeID
from tb_RatingScenario
where RatingScenarioID = @RatingScenarioID

if ( @ScenarioTypeID in (-1,-3) ) -- Hubbing or Country Specific Scenario
Begin

	select tbl7.AccountID ,tbl1.RatingScenarioID ,tbl1.Attribute1ID as AgreementID,
		   tbl1.RatingScenarioName , tbl1.RatingScenarioDescription,
		   tbl2.TrunkID as CommercialTrunkID , tbl2.Trunk as CommercialTrunk,
	       tbl3.CallTypeID , tbl3.CallType,
           tbl4.CountryID , Case When tbl4.CountryID is NULL then 'All Countries' Else tbl4.Country End as Country,
		   tbl5.DirectionID , tbl5.Direction,
		   tbl6.ServiceLevelID ,
		   Case 
				When tbl6.ServiceLevelID is NULL then 'All Service Level' 
				Else tbl6.ServiceLevel 
		   End as ServiceLevel,
		   tbl1.BeginDate , tbl1.EndDate,
		   tbl1.ModifiedDate,
		   UC_Admin.dbo.FN_GetUserName(tbl1.ModifiedByID) as ModifiedByUser
	from tb_RatingScenario tbl1
	inner join tb_Trunk tbl2 on tbl1.Attribute2ID = tbl2.TrunkID
	inner join tb_Calltype tbl3 on tbl1.Attribute3ID = tbl3.CallTypeID
	left join tb_Country tbl4 on isnull(tbl1.Attribute4ID, 0) = tbl4.CountryID
	inner join tb_Direction tbl5 on tbl1.Attribute5ID = tbl5.DirectionID
	left join tb_ServiceLevel tbl6 on isnull(tbl1.Attribute6ID,0) = tbl6.ServiceLevelID
	inner join tb_Agreement tbl7 on tbl1.Attribute1ID = tbl7.AgreementID
	where tbl1.RatingScenarioTypeID = @ScenarioTypeID
	and tbl1.RatingScenarioID = @RatingScenarioID

End
Else
Begin

		set @ErrorDescription = 'ERROR !!! Rating Scenario ID does not belong to a Hubbing scenario'
		set @ResultFlag = 1
		Return 1

End
GO
