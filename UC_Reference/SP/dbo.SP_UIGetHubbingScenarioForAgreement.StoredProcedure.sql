USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetHubbingScenarioForAgreement]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetHubbingScenarioForAgreement]
(
	@AgreementID int,
	@ScenarioTypeID int, -- -1 Hubbing -3 Country Specific,
	@CommercialTrunkID int,
	@CallTypeID int,
	@CountryID int,
	@SelectDate datetime = NULL,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ResultFlag = 0
set @ErrorDescription = NULL

if ( @AgreementID is null )
Begin

		set @ErrorDescription = 'ERROR !!! Agreement ID cannot be NULL. Please pass a valid value'
		set @ResultFlag = 1
		Return 1

End

if not exists ( select 1 from tb_Agreement where AgreementID = @AgreementID )
Begin

		set @ErrorDescription = 'ERROR !!! Agreement ID does not exist in the system. Please check details'
		set @ResultFlag = 1
		Return 1

End

if ( @ScenarioTypeID in (-1,-3) ) 
Begin

    if ( @ScenarioTypeID = -1 ) 
	Begin

	        if (@SelectDate is not NULL )
			Begin

					select tbl1.RatingScenarioID,
					       tbl1.Attribute1ID as AgreementID,
						   tbl1.RatingScenarioName , tbl1.RatingScenarioDescription,
						   tbl2.TrunkID , tbl2.Trunk as CommercialTrunk,
						   tbl3.CallTypeID , tbl3.CallType,
						   NULL as CountryID , 'All Countries' as Country,
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
					inner join tb_Direction tbl5 on tbl1.Attribute5ID = tbl5.DirectionID
					left join tb_ServiceLevel tbl6 on isnull(tbl1.Attribute6ID,0) = tbl6.ServiceLevelID
					where tbl1.RatingScenarioTypeID = @ScenarioTypeID
					and tbl1.Attribute1ID = @AgreementID
					and @SelectDate between tbl1.BeginDate and isnull(tbl1.EndDate , @SelectDate)
					order by tbl2.Trunk , tbl3.CallType , tbl1.BeginDate

			End

	        Else
			Begin

					select tbl1.RatingScenarioID,
					       tbl1.Attribute1ID as AgreementID,
						   tbl1.RatingScenarioName , tbl1.RatingScenarioDescription,
						   tbl2.TrunkID , tbl2.Trunk as CommercialTrunk,
						   tbl3.CallTypeID , tbl3.CallType,
						   NULL as CountryID , 'All Countries' as Country,
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
					inner join tb_Direction tbl5 on tbl1.Attribute5ID = tbl5.DirectionID
					left join tb_ServiceLevel tbl6 on isnull(tbl1.Attribute6ID,0) = tbl6.ServiceLevelID
					where tbl1.RatingScenarioTypeID = @ScenarioTypeID
					and tbl1.Attribute1ID = @AgreementID
					order by tbl2.Trunk , tbl3.CallType , tbl1.BeginDate

			End

	End

    if ( @ScenarioTypeID = -3 ) 
	Begin

	        if (@SelectDate is not NULL )
			Begin

					select tbl1.RatingScenarioID,
					       tbl1.Attribute1ID as AgreementID,
						   tbl1.RatingScenarioName , tbl1.RatingScenarioDescription,
						   tbl2.TrunkID , tbl2.Trunk as CommercialTrunk,
						   tbl3.CallTypeID , tbl3.CallType,
						   tbl4.CountryID , tbl4.Country,
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
					inner join tb_Country tbl4 on isnull(tbl1.Attribute4ID, 0) = tbl4.CountryID
					inner join tb_Direction tbl5 on tbl1.Attribute5ID = tbl5.DirectionID
					left join tb_ServiceLevel tbl6 on isnull(tbl1.Attribute6ID,0) = tbl6.ServiceLevelID
					where tbl1.RatingScenarioTypeID = @ScenarioTypeID
					and @SelectDate between tbl1.BeginDate and isnull(tbl1.EndDate , @SelectDate)
					and tbl1.Attribute1ID = @AgreementID
					and tbl1.Attribute2ID = 
							Case
								When isnull(@CommercialTrunkID, 0) = 0 then tbl1.Attribute2ID 
								Else @CommercialTrunkID
							End
					and tbl1.Attribute3ID = 
							Case
								When isnull(@CallTypeID, 0) = 0 then tbl1.Attribute3ID 
								Else @CallTypeID
							End
					and tbl1.Attribute4ID = 
							Case
								When isnull(@CountryID, 0) = 0 then tbl1.Attribute4ID 
								Else @CountryID
							End
					order by tbl2.Trunk , tbl3.CallType , tbl1.BeginDate

			End

	        Else
			Begin

					select tbl1.RatingScenarioID,
					       tbl1.Attribute1ID as AgreementID,
						   tbl1.RatingScenarioName , tbl1.RatingScenarioDescription,
						   tbl2.TrunkID , tbl2.Trunk as CommercialTrunk,
						   tbl3.CallTypeID , tbl3.CallType,
						   tbl4.CountryID , tbl4.Country,
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
					inner join tb_Country tbl4 on isnull(tbl1.Attribute4ID, 0) = tbl4.CountryID
					inner join tb_Direction tbl5 on tbl1.Attribute5ID = tbl5.DirectionID
					left join tb_ServiceLevel tbl6 on isnull(tbl1.Attribute6ID,0) = tbl6.ServiceLevelID
					where tbl1.RatingScenarioTypeID = @ScenarioTypeID
					and tbl1.Attribute1ID = @AgreementID
					and tbl1.Attribute2ID = 
							Case
								When isnull(@CommercialTrunkID, 0) = 0 then tbl1.Attribute2ID 
								Else @CommercialTrunkID
							End
					and tbl1.Attribute3ID = 
							Case
								When isnull(@CallTypeID, 0) = 0 then tbl1.Attribute3ID 
								Else @CallTypeID
							End
					and tbl1.Attribute4ID = 
							Case
								When isnull(@CountryID, 0) = 0 then tbl1.Attribute4ID 
								Else @CountryID
							End
					order by tbl2.Trunk , tbl3.CallType , tbl1.BeginDate

			End

	End

End

Else
Begin

		set @ErrorDescription = 'ERROR !!! Scenario Type passed is not a valid'
		set @ResultFlag = 1
		Return 1

End
GO
