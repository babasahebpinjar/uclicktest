USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSKPISummarizeAndMartRefresh]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSKPISummarizeAndMartRefresh]
(
	@SelectDate datetime,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int output
)
As

set @ResultFlag = 0
set @ErrorDescription = NULL

Declare @ObjectID int

select @ObjectID = ObjectID
from REFERENCESERVER.UC_Operations.dbo.tb_Object
where ObjectTypeID = 102 -- KPI Refresh Object Type
and ObjectName = 'Data Mart Refresh'

if (@ObjectID is NULL )
Begin

	set @ErrorDescription = 'ERROR !!!! No Object configured in system for Data Mart Refresh'
	set @ResultFlag = 1
	RaisError('%s' , 1, 16 , @ErrorDescription)
	Return 1

End

------------------------------------------------------------------
-- Check to ensure that the KPI refresh Object Instance for the 
-- mentioned select date exists and is in Registered state
------------------------------------------------------------------

Declare @ObjectInstanceID int

select @ObjectInstanceID = ObjectInstanceID
from REFERENCESERVER.UC_Operations.dbo.tb_ObjectInstance 
where ObjectID = @ObjectID 
and ObjectInstance = convert(varchar(10) , @SelectDate , 120)
and statusid = 10210 -- KPI Registered

if ( @ObjectInstanceID = NULL )
Begin

	Return 0 -- Exit the procedure as no steps need to be performed

End

--------------------------------------------------------------------
-- Change the status of the Object Instance to KPI Refresh Running 
-- and then call the subsequent stored procedures for summarization
-- and mart updates
--------------------------------------------------------------------

update REFERENCESERVER.UC_Operations.dbo.tb_ObjectInstance
set statusid = 10211, -- KPI Refresh Running
    Remarks = NULL,
	modifiedDate = getdate()
where ObjectInstanceID = @ObjectInstanceID

---------------------------------------------------------
-- CALL ALL THE SUMMARIZATION AND MART UPDATE PROCEDURES
---------------------------------------------------------

------------------------------------------------------
-- STEP 1: Get all the data from FTR Summary tables on
-- each CDR database to the Report Server
------------------------------------------------------

----------------------------------------------------------------
-- Create the temporary table to store all the collected data
-- from the summarized CDR databases for the call date
-----------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempFTRSummary') )
		Drop table #tempFTRSummary

Create Table #tempFTRSummary
(
   ObjectInstanceID int,
   CallDate datetime,
   CallHour int,
   CallDuration int,
   CircuitDuration int,
   Answered int,
   Seized int,
   CallTypeID int,
   INAccountID int,
   OutAccountID int,
   INTrunkID int,
   OutTrunkID int,
   INCommercialTrunkID int,
   OUTCOmmercialTrunkID int,
   INDestinationID int,
   OUTDestinationID int,
   RoutingDestinationID int,
   INServiceLevelID int,
   OUTServiceLevelID int,
   INRatePlanID int,
   OUTRatePlanID int,
   INRatingMethodID int,
   OUTRatingMethodID int,
   INRoundedCallDuration int,
   OutRoundedCallDuration int,
   INChargeDuration Decimal(19,4),
   OUTChargeDuration Decimal(19,4),
   INAmount Decimal(19,6),
   OUTAmount Decimal(19,6),
   INRate Decimal(19,6),
   OUTRate Decimal(19,6),
   INRateTypeID	int,
   OUTRateTypeID int,
   INCurrencyID	int,
   OUTCurrencyID int,
   INErrorFlag int,
   OUTErrorFlag int
)

Begin Try

			set @ErrorDescription = NULL
			set @ResultFlag = 0

			Exec SP_BSCollectTrafficFromCDRDatabases @ObjectInstanceID, @SelectDate , @ErrorDescription Output , @ResultFlag Output

			if ( @ResultFlag = 1 )
			Begin

			       set @ErrorDescription = 'ERROR !!!! During Collection of Summarized Data from CDR Databases. ' + @ErrorDescription
				   GOTO PROCESSEND	

			End

End Try

Begin Catch

			set @ErrorDescription = 'ERROR !!!! During Collection of Summarized Data from CDR Databases. ' + ERROR_MESSAGE()
			set @ResultFlag = 1
			GOTO PROCESSEND

End Catch


------------------------------------------------------
-- STEP 2: Populate Hourly IN And OUT Traffic Mart
------------------------------------------------------


Begin Try

			set @ErrorDescription = NULL
			set @ResultFlag = 0

			Exec SP_BSPopulateHourlyTrafficMart @ObjectInstanceID ,@SelectDate , @ErrorDescription Output , @ResultFlag Output

			if ( @ResultFlag = 1 )
			Begin

			       set @ErrorDescription = 'ERROR !!!! During population of Hourly IN and OUT Traffic Mart. ' + @ErrorDescription
				   GOTO PROCESSEND	

			End

End Try

Begin Catch

			set @ErrorDescription = 'ERROR !!!! During population of Hourly IN and OUT Traffic Mart. ' + ERROR_MESSAGE()
			set @ResultFlag = 1
			GOTO PROCESSEND

End Catch


------------------------------------------------------
-- STEP 3: Populate Daily IN And OUT Traffic Mart
------------------------------------------------------


Begin Try

			set @ErrorDescription = NULL
			set @ResultFlag = 0

			Exec SP_BSPopulateDailyTrafficMart @ObjectInstanceID ,@SelectDate , @ErrorDescription Output , @ResultFlag Output

			if ( @ResultFlag = 1 )
			Begin

			       set @ErrorDescription = 'ERROR !!!! During population of Daily IN and OUT Traffic Mart. ' + @ErrorDescription
				   GOTO PROCESSEND	

			End

End Try

Begin Catch

			set @ErrorDescription = 'ERROR !!!! During population of Daily IN and OUT Traffic Mart. ' + ERROR_MESSAGE()
			set @ResultFlag = 1
			GOTO PROCESSEND

End Catch


--------------------------------------------------------------------------------------
-- STEP 4: Populate Daily Financial Transaction information for Inbound And Outbound
--         directly as segregated records
--------------------------------------------------------------------------------------
Begin Try

			set @ErrorDescription = NULL
			set @ResultFlag = 0

			Exec SP_BSPopulateDailyInUnionOutFinancialMart @ObjectInstanceID ,@SelectDate , @ErrorDescription Output , @ResultFlag Output

			if ( @ResultFlag = 1 )
			Begin

			       set @ErrorDescription = 'ERROR !!!! During population of Daily IN Union OUT Financial Mart. ' + @ErrorDescription
				   GOTO PROCESSEND	

			End

End Try

Begin Catch

			set @ErrorDescription = 'ERROR !!!! During population of Daily IN Union OUT Financial Mart. ' + ERROR_MESSAGE()
			set @ResultFlag = 1
			GOTO PROCESSEND

End Catch


-----------------------------------------------------
-- STEP 5: Populate the CDR Error Sumamry and Details
-----------------------------------------------------
Begin Try

			set @ErrorDescription = NULL
			set @ResultFlag = 0

			Exec SP_BSSummarizeCDRErrorTrafficDaily @ObjectInstanceID ,@SelectDate , @ErrorDescription Output , @ResultFlag Output

			if ( @ResultFlag = 1 )
			Begin

			       set @ErrorDescription = 'ERROR !!!! During population of CDR Error Details and Summary. ' + @ErrorDescription
				   GOTO PROCESSEND	

			End

End Try

Begin Catch

			set @ErrorDescription = 'ERROR !!!! During population of CDR Error Details and Summary. ' + ERROR_MESSAGE()
			set @ResultFlag = 1
			GOTO PROCESSEND

End Catch


PROCESSEND:

if  ( @ResultFlag = 1)
Begin

		update REFERENCESERVER.UC_Operations.dbo.tb_ObjectInstance
		set statusid = 10213, -- KPI Refresh Failed
		    Remarks = @ErrorDescription,
			modifiedDate = Getdate()
		where ObjectInstanceID = @ObjectInstanceID

End

Else
Begin

		update REFERENCESERVER.UC_Operations.dbo.tb_ObjectInstance
		set statusid = 10212,-- KPI Refresh Completed
		    ProcessEndTime = Getdate(),
			modifiedDate = getdate()
		where ObjectInstanceID = @ObjectInstanceID

End

------------------------------------------------------------
-- Drop all the temporary tables post processing activity
------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempFTRSummary') )
		Drop table #tempFTRSummary

Return 0
GO
