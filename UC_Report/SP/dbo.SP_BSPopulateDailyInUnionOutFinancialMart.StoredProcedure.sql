USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSPopulateDailyInUnionOutFinancialMart]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSPopulateDailyInUnionOutFinancialMart]
(

    @InstanceID int,
	@SelectDate datetime,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @ObjectInstanceTaskLogID varchar(100)

-----------------------------------------------------------------
-- Create an entry in the Object Instance Task Log for this task
-----------------------------------------------------------------

Exec REFERENCESERVER.UC_Operations.dbo.SP_BSObjectInstanceTaskLogInsert @InstanceID , 'Populate Daily IN Union OUT Financial Mart' , @ObjectInstanceTaskLogID Output


-----------------------------------------------------------------------------------------------
-- Delete data for all the selected dates from the table and insert new summarized information
-----------------------------------------------------------------------------------------------


Delete from tb_DailyINUnionOutFinancial
where calldate =  @SelectDate


Begin Try

            ---------------------------------------------
			-- INBOOUND DIRECTON FINANCIAL INFORMATION
			---------------------------------------------

			insert into tb_DailyINUnionOutFinancial
			(
			    CallDate,
				DirectionID,
				CallDuration,
				CircuitDuration,
				Answered,
				Seized,
				CallTypeID,
				AccountID,
				TrunkID,
				CommercialTrunkID,
				SettlementDestinationID,
				RoutingDestinationID,
				INServiceLevelID,
				OUTServiceLevelID,
				RatePlanID,
				RatingMethodID,
				RoundedCallDuration,
				ChargeDuration,
				Amount,
				Rate,
				RateTypeID,
				CurrencyID,
				ErrorIndicator
			)
			select			
			   CallDate,
			   1, -- Inbound Direction
			   sum(CallDuration),
			   sum(CircuitDuration),
			   sum(Answered),
			   sum(Seized),			   
			   CallTypeID,
			   INAccountID,
               INTrunkID,
			   INCommercialTrunkID,
			   INDestinationID,
			   RoutingDestinationID,
			   INServiceLevelID,
			   OUTServiceLEvelID,
			   INRatePlanID,
			   INRatingMethodID,
			   sum(INRoundedCallDuration),
			   sum(INChargeDuration),
			   sum(INAmount),
			   Case
					When sum(INChargeDuration) = 0 then 0
					Else convert(Decimal(19,6) ,sum(INAmount)/sum(INChargeDuration))
			   End,
			   INRateTypeID,
			   INCurrencyID,
			   Case
			      When isNULL(INErrorFlag,0) = 0 then 0
				  Else 1
			   End
			from #tempFTRSummary
			where calldate = @SelectDate
			Group by   CallDate,
					   CallTypeID,
					   INAccountID,
					   INTrunkID,
					   INCommercialTrunkID,
					   INDestinationID,
					   RoutingDestinationID,
					   INServiceLevelID,
					   OUTServiceLEvelID,
					   INRatePlanID,
					   INRatingMethodID,
					   INRateTypeID,
					   INCurrencyID,
					   Case
						  When isNULL(INErrorFlag,0) = 0 then 0
						  Else 1
					   End

            ---------------------------------------------
			-- OUTBOOUND DIRECTON FINANCIAL INFORMATION
			---------------------------------------------

			insert into tb_DailyINUnionOutFinancial
			(
			    CallDate,
				DirectionID,
				CallDuration,
				CircuitDuration,
				Answered,
				Seized,
				CallTypeID,
				AccountID,
				TrunkID,
				CommercialTrunkID,
				SettlementDestinationID,
				RoutingDestinationID,
				INServiceLevelID,
				OUTServiceLevelID,
				RatePlanID,
				RatingMethodID,
				RoundedCallDuration,
				ChargeDuration,
				Amount,
				Rate,
				RateTypeID,
				CurrencyID,
				ErrorIndicator
			)
			select			
			   CallDate,
			   2, -- Outbound Direction
			   sum(CallDuration),
			   sum(CircuitDuration),
			   sum(Answered),
			   sum(Seized),			   
			   CallTypeID,
			   OUTAccountID,
               OUTTrunkID,
			   OUTCommercialTrunkID,
			   OUTDestinationID,
			   RoutingDestinationID,
			   INServiceLevelID,
			   OUTServiceLEvelID,
			   OUTRatePlanID,
			   OUTRatingMethodID,
			   sum(OUTRoundedCallDuration),
			   sum(OUTChargeDuration),
			   sum(OUTAmount),
			   Case
					When sum(OUTChargeDuration) = 0 then 0
					Else convert(Decimal(19,6) ,sum(OUTAmount)/sum(OUTChargeDuration))
			   End,
			   OUTRateTypeID,
			   OUTCurrencyID,
			   Case
			      When isNULL(OUTErrorFlag,0) = 0 then 0
				  Else 1
			   End
			from #tempFTRSummary
			where calldate = @SelectDate
			Group by   CallDate,
					   CallTypeID,
					   OUTAccountID,
					   OUTTrunkID,
					   OUTCommercialTrunkID,
					   OUTDestinationID,
					   RoutingDestinationID,
					   INServiceLevelID,
					   OUTServiceLEvelID,
					   OUTRatePlanID,
					   OUTRatingMethodID,
					   OUTRateTypeID,
					   OUTCurrencyID,
					   Case
						  When isNULL(OUTErrorFlag,0) = 0 then 0
						  Else 1
					   End

End Try

Begin Catch

			set @ErrorDescription = 'Error !! Inserting data into Daily IN Union Out Financial Mart. '+ERROR_MESSAGE()	     
			set @ResultFlag = 1
			GOTO ENDPROCESS				
			
End Catch


Declare @TaskEndDate datetime

set @TaskEndDate = Getdate()

Exec REFERENCESERVER.UC_Operations.dbo.SP_BSObjectInstanceTaskLogUpdate @ObjectInstanceTaskLogID,
                                                                       @TaskEndDate,
																	   NULL, NULL,
																	   NULL,NULL, 
																	   NULL, NULL

ENDPROCESS:

Return 0

GO
