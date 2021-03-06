USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSSummarizeTrafficDaily]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSSummarizeTrafficDaily]
(
	@BeginDate datetime,
	@EndDate datetime,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

----------------------------------------------------------
-- Check if Start date is less than equal to End Date
----------------------------------------------------------

if (@BeginDate > @EndDate)
Begin

		set @ErrorDescription = 'ERROR !!! Begin Date should less than equal to End Date'
		set @ResultFlag = 1
		Return 1

End

----------------------------------------------------------------------------------------
-- Delete data for all the selected dates from the main summary table and insert new
-- summarized information
-----------------------------------------------------------------------------------------

--select 'Before Delete...' ,count(*)
--from tb_FTRSummaryDaily

Delete from tb_FTRSummaryDaily
where calldate between @Begindate and @EndDate


--select 'Afer Delete...' ,count(*)
--from tb_FTRSummaryDaily

Begin Try

			insert into tb_FTRSummaryDaily
			(
			   CallDate,
			   CallDuration,
			   CircuitDuration,
			   Answered,
			   Seized,			   
			   CallTypeID,
			   INAccountID,
			   OutAccountID,
               INTrunkID,
			   OutTrunkID,
			   INCommercialTrunkID,
			   OUTCOmmercialTrunkID,
			   INDestinationID,
               OUTDestinationID,
			   RoutingDestinationID,
			   INServiceLevelID,
			   OUTServiceLEvelID,
               INRatePlanID,
			   OUTRatePlanID,
			   INRatingMethodID,
			   OUTRatingMethodID,
			   INRoundedCallDuration,
               OutRoundedCallDuration,
			   INChargeDuration,
			   OUTChargeDuration,
			   INAmount,
			   OUTAmount,
			   INRate,
			   OUTRate,
			   INErrorFlag,
			   OUTErrorFlag
			)
			select			
			   CallDate,
			   sum(CallDuration),
			   sum(CircuitDuration),
			   sum(Answered),
			   sum(Seized),			   
			   CallTypeID,
			   INAccountID,
			   OutAccountID,
               INTrunkID,
			   OutTrunkID,
			   INCommercialTrunkID,
			   OUTCOmmercialTrunkID,
			   INDestinationID,
               OUTDestinationID,
			   RoutingDestinationID,
			   INServiceLevelID,
			   OUTServiceLEvelID,
               INRatePlanID,
			   OUTRatePlanID,
			   INRatingMethodID,
			   OUTRatingMethodID,
			   sum(INRoundedCallDuration),
               sum(OutRoundedCallDuration),
			   sum(INChargeDuration),
			   sum(OUTChargeDuration),
			   sum(INAmount),
			   sum(OUTAmount),
			   Case
					When sum(INChargeDuration) = 0 then 0
					Else convert(Decimal(19,6) ,sum(INAmount)/sum(INChargeDuration))
			   End,
			   Case
					When sum(OUTChargeDuration) = 0 then 0
					Else convert(Decimal(19,6) ,sum(OUTAmount)/sum(OUTChargeDuration))
			   End,
			   Case
			      When isNULL(INErrorFlag,0) = 0 then 0
				  Else 1
			   End,
			   Case
			      When isNULL(OUTErrorFlag,0) = 0 then 0
				  Else 1
			   End
			from tb_FTRSummary
			where calldate between @BeginDate and @EndDate
			Group by   CallDate,
					   CallTypeID,
					   INAccountID,
					   OutAccountID,
					   INTrunkID,
					   OutTrunkID,
					   INCommercialTrunkID,
					   OUTCOmmercialTrunkID,
					   INDestinationID,
					   OUTDestinationID,
					   RoutingDestinationID,
					   INServiceLevelID,
					   OUTServiceLEvelID,
					   INRatePlanID,
					   OUTRatePlanID,
					   INRatingMethodID,
					   OUTRatingMethodID,
					   INRate,
					   OUTRate,
					   Case
						  When isNULL(INErrorFlag,0) = 0 then 0
						  Else 1
					   End,
					   Case
						  When isNULL(OUTErrorFlag,0) = 0 then 0
						  Else 1
					   End

End Try

Begin Catch

			set @ErrorDescription = 'Error !! Inserting data into Daily Financial Summary table from Master Summary. '+ERROR_MESSAGE()	     
			set @ResultFlag = 1				
			
End Catch

--select 'Post Insert...' ,count(*)
--from tb_FTRSummaryDaily


Return 0

GO
