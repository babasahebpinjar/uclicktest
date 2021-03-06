USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSPopulateHourlyTrafficMart]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSPopulateHourlyTrafficMart]
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

Exec REFERENCESERVER.UC_Operations.dbo.SP_BSObjectInstanceTaskLogInsert @InstanceID , 'Populate Hourly Traffic Mart' , @ObjectInstanceTaskLogID Output


-----------------------------------------------------------------------------------------------
-- Delete data for all the selected dates from the table and insert new summarized information
-----------------------------------------------------------------------------------------------


Delete from tb_HourlyINCrossOutTrafficMart
where calldate =  @SelectDate


Begin Try

			insert into tb_HourlyINCrossOutTrafficMart
			(
			   CallDate,
			   CallHour,
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
 			   INRoundedCallDuration,
               OutRoundedCallDuration,
			   INChargeDuration,
			   OUTChargeDuration
			)
			select			
			   CallDate,
			   CallHour,
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
			   sum(INRoundedCallDuration),
               sum(OutRoundedCallDuration),
			   sum(INChargeDuration),
			   sum(OUTChargeDuration)
			from #tempFTRSummary
			where calldate = @SelectDate
			Group by   CallDate,
			           CallHour,
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
					   OUTServiceLEvelID

End Try

Begin Catch

			set @ErrorDescription = 'Error !! Inserting data into Hourly IN And Out Traffic Mart. '+ERROR_MESSAGE()	     
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
