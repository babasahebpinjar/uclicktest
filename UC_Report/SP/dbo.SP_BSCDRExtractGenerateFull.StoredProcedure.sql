USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSCDRExtractGenerateFull]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_BSCDRExtractGenerateFull]
(
    @BeginDate datetime,
    @EndDate datetime,
    @CallTypeID int,
	@INAccountIDList nvarchar(max),
	@OUTAccountIDList nvarchar(max),
	@INCommercialTrunkIDList nvarchar(max),
	@OUTCommercialTrunkIDList nvarchar(max),
	@INTechnicalTrunkIDList nvarchar(max),
	@OUTTechnicalTrunkIDList nvarchar(max),
	@CountryIDList nvarchar(max),
	@DestinationIDList nvarchar(max),
 	@ServiceLevelIDList nvarchar(max),
	@ConditionClause nvarchar(max),
	@DisplayFieldList nvarchar(max),
	@CDRExtractFileName varchar(1000) Output,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As 

set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @AllCountryFlag int = 0,
        @AllServiceLevelFlag int = 0,
		@AllDestinationFlag int = 0,
		@INAllAccountFlag int = 0,
		@INAllCommercialTrunkFlag int = 0,
		@INAllTechnicalTrunkFlag int = 0,
		@OUTAllAccountFlag int = 0,
		@OUTAllCommercialTrunkFlag int = 0,
		@OUTAllTechnicalTrunkFlag int = 0,
		@ConditionClauseOptimize nvarchar(max)

-------------------------------------------------------------
-- Set the CALL TYPE to NULL in case the value passed is 0
-- indicating that all CALL TYPES need to be considered
-------------------------------------------------------------

if ( @CallTypeID = 0 )
	set @CallTypeID = NULL

--Select 'Step 1..' , getdate()

Begin Try

-----------------------------------------------------------
-- Create a table list of the selected display fields from
-- the parameter list
------------------------------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDisplayFieldIDTable') )
				Drop table #TempDisplayFieldIDTable

		Create Table #TempDisplayFieldIDTable (DisplayFieldID varchar(100) )


		insert into #TempDisplayFieldIDTable
		select * from FN_ParseValueList ( @DisplayFieldList )

		----------------------------------------------------------------
		-- Check to ensure that none of the values are non numeric
		----------------------------------------------------------------

		if exists ( select 1 from #TempDisplayFieldIDTable where ISNUMERIC(DisplayFieldID) = 0 )
		Begin

			set @ErrorDescription = 'ERROR !!! List of Display Field IDs passed contain a non numeric value'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End

		------------------------------------------------------
		-- Check if the All the Display Fields have been selected 
		------------------------------------------------------

		if exists (
						select 1 
						from #TempDisplayFieldIDTable 
						where DisplayFieldID = 0
				  )
		Begin

                  Delete from #TempDisplayFieldIDTable

				  insert into #TempDisplayFieldIDTable
				  Select distinct CDRExtractMasterReferenceID
				  from tb_CDRExtractMasterReference
				  order by CDRExtractMasterReferenceID Desc

				  GOTO PROCESSINACCOUNT
				  
		End
		
        -----------------------------------------------------------------
		-- Check to ensure that all the Account IDs passed are valid values
		-----------------------------------------------------------------
		
		if exists ( 
						select 1 
						from #TempDisplayFieldIDTable 
						where DisplayFieldID not in
						(
							Select CDRExtractMasterReferenceID
							from tb_CDRExtractMasterReference
							where flag & 1 <> 1
						)
					)
		Begin

			set @ErrorDescription = 'ERROR !!! List of Display Field IDs passed contain value(s) which are not valid or do not exist'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End


PROCESSINACCOUNT:
-----------------------------------------------------------------
-- Create table for list of selected IN Accounts from the parameter
-- passed
-----------------------------------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempINAccountIDTable') )
				Drop table #TempINAccountIDTable

		Create Table #TempINAccountIDTable (AccountID varchar(100) )


		insert into #TempINAccountIDTable
		select * from FN_ParseValueList ( @INAccountIDList )

		----------------------------------------------------------------
		-- Check to ensure that none of the values are non numeric
		----------------------------------------------------------------

		if exists ( select 1 from #TempINAccountIDTable where ISNUMERIC(AccountID) = 0 )
		Begin

			set @ErrorDescription = 'ERROR !!! List of IN Account IDs passed contain a non numeric value'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End

		------------------------------------------------------
		-- Check if the All the Accounts have been selected 
		------------------------------------------------------

		if exists (
						select 1 
						from #TempINAccountIDTable 
						where AccountID = 0
				  )
		Begin

                  set @INAllAccountFlag = 1
				  GOTO PROCESSOUTACCOUNT
				  
		End
		
        -----------------------------------------------------------------
		-- Check to ensure that all the Account IDs passed are valid values
		-----------------------------------------------------------------
		
		if exists ( 
						select 1 
						from #TempINAccountIDTable 
						where AccountID not in
						(
							Select AccountID
							from ReferenceServer.UC_Reference.dbo.tb_Account
							where flag & 1 <> 1
						)
					)
		Begin

			set @ErrorDescription = 'ERROR !!! List of IN Account IDs passed contain value(s) which are not valid or do not exist'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End

PROCESSOUTACCOUNT:

-----------------------------------------------------------------
-- Create table for list of selected OUT Accounts from the parameter
-- passed
-----------------------------------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempOUTAccountIDTable') )
				Drop table #TempOUTAccountIDTable

		Create Table #TempOUTAccountIDTable (AccountID varchar(100) )


		insert into #TempOUTAccountIDTable
		select * from FN_ParseValueList ( @OUTAccountIDList )

		----------------------------------------------------------------
		-- Check to ensure that none of the values are non numeric
		----------------------------------------------------------------

		if exists ( select 1 from #TempOUTAccountIDTable where ISNUMERIC(AccountID) = 0 )
		Begin

			set @ErrorDescription = 'ERROR !!! List of OUT Account IDs passed contain a non numeric value'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End

		------------------------------------------------------
		-- Check if the All the Accounts have been selected 
		------------------------------------------------------

		if exists (
						select 1 
						from #TempOUTAccountIDTable 
						where AccountID = 0
				  )
		Begin

                  set @OUTAllAccountFlag = 1
				  GOTO PROCESSINCOMMERCIALTRUNK
				  
		End
		
        -----------------------------------------------------------------
		-- Check to ensure that all the Account IDs passed are valid values
		-----------------------------------------------------------------
		
		if exists ( 
						select 1 
						from #TempOUTAccountIDTable 
						where AccountID not in
						(
							Select AccountID
							from ReferenceServer.UC_Reference.dbo.tb_Account
							where flag & 1 <> 1
						)
					)
		Begin

			set @ErrorDescription = 'ERROR !!! List of OUT Account IDs passed contain value(s) which are not valid or do not exist'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End

PROCESSINCOMMERCIALTRUNK:

-----------------------------------------------------------------
-- Create table for list of selected IN Commercial Trunks from the 
-- parameter passed
-----------------------------------------------------------------
		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempINCommercialTrunkIDTable') )
				Drop table #TempINCommercialTrunkIDTable

		Create table #TempINCommercialTrunkIDTable (CommercialTrunkID varchar(100) )


		insert into #TempINCommercialTrunkIDTable
		select * from FN_ParseValueList ( @INCommercialTrunkIDList )

		----------------------------------------------------------------
		-- Check to ensure that none of the values are non numeric
		----------------------------------------------------------------

		if exists ( select 1 from #TempINCommercialTrunkIDTable where ISNUMERIC(CommercialTrunkID) = 0 )
		Begin

			set @ErrorDescription = 'ERROR !!! List of IN CommercialTrunk IDs passed contain a non numeric value'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End

		------------------------------------------------------
		-- Check if the All the CommercialTrunks have been selected 
		------------------------------------------------------

		if exists (
						select 1 
						from #TempINCommercialTrunkIDTable 
						where CommercialTrunkID = 0
				  )
		Begin

                  set @INAllCommercialTrunkFlag = 1
				  GOTO PROCESSOUTCOMMERCIALTRUNK
				  
		End
		
        -----------------------------------------------------------------
		-- Check to ensure that all the CommercialTrunk IDs passed are valid values
		-----------------------------------------------------------------
		
		if exists ( 
						select 1 
						from #TempINCommercialTrunkIDTable 
						where CommercialTrunkID not in
						(
							Select TrunkID
							from ReferenceServer.UC_Reference.dbo.tb_Trunk
							where trunktypeID = 9 -- Commercial trunk
							and flag & 1 <> 1
						)
					)
		Begin

			set @ErrorDescription = 'ERROR !!! List of IN CommercialTrunk IDs passed contain value(s) which are not valid or do not exist'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End

PROCESSOUTCOMMERCIALTRUNK:

-----------------------------------------------------------------
-- Create table for list of selected OUT Commercial Trunks from the 
-- parameter passed
-----------------------------------------------------------------
		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempOUTCommercialTrunkIDTable') )
				Drop table #TempOUTCommercialTrunkIDTable

		Create table #TempOUTCommercialTrunkIDTable (CommercialTrunkID varchar(100) )


		insert into #TempOUTCommercialTrunkIDTable
		select * from FN_ParseValueList ( @OUTCommercialTrunkIDList )

		----------------------------------------------------------------
		-- Check to ensure that none of the values are non numeric
		----------------------------------------------------------------

		if exists ( select 1 from #TempOUTCommercialTrunkIDTable where ISNUMERIC(CommercialTrunkID) = 0 )
		Begin

			set @ErrorDescription = 'ERROR !!! List of OUT CommercialTrunk IDs passed contain a non numeric value'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End

		------------------------------------------------------
		-- Check if the All the CommercialTrunks have been selected 
		------------------------------------------------------

		if exists (
						select 1 
						from #TempOUTCommercialTrunkIDTable 
						where CommercialTrunkID = 0
				  )
		Begin

                  set @OUTAllCommercialTrunkFlag = 1
				  GOTO PROCESSINTRUNK
				  
		End
		
        -----------------------------------------------------------------
		-- Check to ensure that all the CommercialTrunk IDs passed are valid values
		-----------------------------------------------------------------
		
		if exists ( 
						select 1 
						from #TempOUTCommercialTrunkIDTable 
						where CommercialTrunkID not in
						(
							Select TrunkID
							from ReferenceServer.UC_Reference.dbo.tb_Trunk
							where trunktypeID = 9 -- Commercial trunk
							and flag & 1 <> 1
						)
					)
		Begin

			set @ErrorDescription = 'ERROR !!! List of OUT CommercialTrunk IDs passed contain value(s) which are not valid or do not exist'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End

PROCESSINTRUNK:

-----------------------------------------------------------------
-- Create table for list of selected IN Technical Trunks from the 
-- parameter passed
-----------------------------------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempINTechnicalTrunkIDTable') )
				Drop table #TempINTechnicalTrunkIDTable

		Create table #TempINTechnicalTrunkIDTable (TechnicalTrunkID varchar(100) )


		insert into #TempINTechnicalTrunkIDTable
		select * from FN_ParseValueList ( @INTechnicalTrunkIDList )

		----------------------------------------------------------------
		-- Check to ensure that none of the values are non numeric
		----------------------------------------------------------------

		if exists ( select 1 from #TempINTechnicalTrunkIDTable where ISNUMERIC(TechnicalTrunkID) = 0 )
		Begin

			set @ErrorDescription = 'ERROR !!! List of IN TechnicalTrunk IDs passed contain a non numeric value'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End

		------------------------------------------------------
		-- Check if the All the TechnicalTrunks have been selected 
		------------------------------------------------------

		if exists (
						select 1 
						from #TempINTechnicalTrunkIDTable 
						where TechnicalTrunkID = 0
				  )
		Begin

                  set @INAllTechnicalTrunkFlag = 1
				  GOTO PROCESSOUTTRUNK
				  
		End
		
        -----------------------------------------------------------------
		-- Check to ensure that all the TechnicalTrunk IDs passed are valid values
		-----------------------------------------------------------------
		
		if exists ( 
						select 1 
						from #TempINTechnicalTrunkIDTable 
						where TechnicalTrunkID not in
						(
							Select TrunkID
							from ReferenceServer.UC_Reference.dbo.tb_Trunk
							where trunktypeID <> 9 -- Technical Trunks
							and flag & 1 <> 1
						)
					)
		Begin

			set @ErrorDescription = 'ERROR !!! List of IN TechnicalTrunk IDs passed contain value(s) which are not valid or do not exist'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End

PROCESSOUTTRUNK:

-----------------------------------------------------------------
-- Create table for list of selected IN Technical Trunks from the 
-- parameter passed
-----------------------------------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempOUTTechnicalTrunkIDTable') )
				Drop table #TempOUTTechnicalTrunkIDTable

		Create table #TempOUTTechnicalTrunkIDTable (TechnicalTrunkID varchar(100) )


		insert into #TempOUTTechnicalTrunkIDTable
		select * from FN_ParseValueList ( @OUTTechnicalTrunkIDList )

		----------------------------------------------------------------
		-- Check to ensure that none of the values are non numeric
		----------------------------------------------------------------

		if exists ( select 1 from #TempOUTTechnicalTrunkIDTable where ISNUMERIC(TechnicalTrunkID) = 0 )
		Begin

			set @ErrorDescription = 'ERROR !!! List of OUT TechnicalTrunk IDs passed contain a non numeric value'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End

		------------------------------------------------------
		-- Check if the All the TechnicalTrunks have been selected 
		------------------------------------------------------

		if exists (
						select 1 
						from #TempOUTTechnicalTrunkIDTable 
						where TechnicalTrunkID = 0
				  )
		Begin

                  set @OUTAllTechnicalTrunkFlag = 1
				  GOTO PROCESSCOUNTRY
				  
		End
		
        -----------------------------------------------------------------
		-- Check to ensure that all the TechnicalTrunk IDs passed are valid values
		-----------------------------------------------------------------
		
		if exists ( 
						select 1 
						from #TempOUTTechnicalTrunkIDTable 
						where TechnicalTrunkID not in
						(
							Select TrunkID
							from ReferenceServer.UC_Reference.dbo.tb_Trunk
							where trunktypeID <> 9 -- Technical Trunks
							and flag & 1 <> 1
						)
					)
		Begin

			set @ErrorDescription = 'ERROR !!! List of OUT TechnicalTrunk IDs passed contain value(s) which are not valid or do not exist'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End

PROCESSCOUNTRY:
-----------------------------------------------------------------
-- Create table for list of all selected Countries from the 
-- parameter passed
-----------------------------------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCountryIDTable') )
				Drop table #TempCountryIDTable


		Create table #TempCountryIDTable (CountryID varchar(100) )
		
		insert into #TempCountryIDTable
		select * from FN_ParseValueList ( @CountryIDList )

		----------------------------------------------------------------
		-- Check to ensure that none of the values are non numeric
		----------------------------------------------------------------

		if exists ( select 1 from #TempCountryIDTable where ISNUMERIC(CountryID) = 0 )
		Begin

			set @ErrorDescription = 'ERROR !!! List of Country IDs passed contain a non numeric value'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End

		------------------------------------------------------
		-- Check if the All the countries have been selected 
		------------------------------------------------------

		if exists (
						select 1 
						from #TempCountryIDTable 
						where CountryID = 0
				  )
		Begin

                  set @AllCountryFlag = 1
				  GOTO PROCESSSERVICELEVEL
				  
		End
		
        -----------------------------------------------------------------
		-- Check to ensure that all the Country IDs passed are valid values
		-----------------------------------------------------------------
		
		if exists ( 
						select 1 
						from #TempCountryIDTable 
						where CountryID not in
						(
							Select CountryID
							from ReferenceServer.UC_Reference.dbo.tb_country
							where flag & 1 <> 1
						)
					)
		Begin

			set @ErrorDescription = 'ERROR !!! List of Country IDs passed contain value(s) which are not valid or do not exist'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End 

PROCESSSERVICELEVEL:

		-----------------------------------------------------------------
		-- Create table for list of all selected Service Levels from the 
		-- parameter passed
		-----------------------------------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempServiceLevelIDTable') )
				Drop table #TempServiceLevelIDTable

		Create table #TempServiceLevelIDTable (ServiceLevelID varchar(100) )


		insert into #TempServiceLevelIDTable
		select * from FN_ParseValueList ( @ServiceLevelIDList )

		----------------------------------------------------------------
		-- Check to ensure that none of the values are non numeric
		----------------------------------------------------------------

		if exists ( select 1 from #TempServiceLevelIDTable where ISNUMERIC(ServiceLevelID) = 0 )
		Begin

			set @ErrorDescription = 'ERROR !!! List of Service Level IDs passed contain a non numeric value'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End

		------------------------------------------------------
		-- Check if the All the Service Levels have been selected 
		------------------------------------------------------

		if exists (
						select 1 
						from #TempServiceLevelIDTable 
						where ServiceLevelID = 0
				  )
		Begin

				  set @AllServiceLevelFlag = 1
				  GOTO PROCESSDESTINATIONLIST
				  
		End
		
        --------------------------------------------------------------------------
		-- Check to ensure that all the Service Level IDs passed are valid values
		--------------------------------------------------------------------------
		
		if exists ( 
						select 1 
						from #TempServiceLevelIDTable 
						where ServiceLevelID not in
						(
							Select ServiceLevelID
							from ReferenceServer.UC_Reference.dbo.tb_ServiceLevel
							where DirectionID = 1 -- All INBOUND Service Levels
							and flag & 1 <> 1
						)
					)
		Begin

			set @ErrorDescription = 'ERROR !!! List of Service Level IDs passed contain value(s) which are not valid or do not exist'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End 

PROCESSDESTINATIONLIST:

		-----------------------------------------------------------------
		-- Create table for list of all selected Destinations from the 
		-- parameter passed
		-----------------------------------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDestinationIDTable') )
				Drop table #TempDestinationIDTable

		Create table  #TempDestinationIDTable (DestinationID varchar(100) )


		insert into #TempDestinationIDTable
		select * from FN_ParseValueList ( @DestinationIDList )

		----------------------------------------------------------------
		-- Check to ensure that none of the values are non numeric
		----------------------------------------------------------------

		if exists ( select 1 from #TempDestinationIDTable where ISNUMERIC(DestinationID) = 0 )
		Begin

			set @ErrorDescription = 'ERROR !!! List of Destination IDs passed contain a non numeric value'
			set @ResultFlag = 1
			Return 1

		End

		------------------------------------------------------
		-- Check if the All the Detinations have been selected 
		------------------------------------------------------

		if exists (
						select 1 
						from #TempDestinationIDTable 
						where DEstinationID = 0
				  )
		Begin

				  set @AllDestinationFlag = 1
				  GOTO PREPAREMASTERREFERENCEDATA
				  
		End
		
        --------------------------------------------------------------------------
		-- Check to ensure that all the Destinations passed are valid values
		--------------------------------------------------------------------------
		
		if exists ( 
						select 1 
						from #TempDestinationIDTable 
						where DestinationID not in
						(
							Select DestinationID
							from ReferenceServer.UC_Reference.dbo.tb_Destination
							where numberplanID = -1 -- All Routing Destinations
							and flag & 1 <> 1
						)
					)
		Begin

			set @ErrorDescription = 'ERROR !!! List of Destination IDs passed contain value(s) which are not valid or do not exist'
			set @ResultFlag = 1
			Return 1

		End 

End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!! While optimizing multi select parameter list. ' + ERROR_MESSAGE()
	set @ResultFlag = 1
	GOTO ENDPROCESS

End Catch

PREPAREMASTERREFERENCEDATA:

Begin Try

		-----------------------------------------------------------------
		-- Create temporary tables to hold to master reference data
		-- for different attributes
		-----------------------------------------------------------------

		-------------
		-- ACCOUNT
		-------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAccountMaster') )
			Drop table #TempAccountMaster

		select AccountID , Account
		into #TempAccountMaster
		from ReferenceServer.UC_Reference.dbo.tb_Account

		-------------
		-- SWITCH
		-------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempSwitchMaster') )
			Drop table #TempSwitchMaster

		select SwitchID , Switch
		into #TempSwitchMaster
		from ReferenceServer.UC_Reference.dbo.tb_Switch

		-------------------
		-- TECHNICAL TRUNK
		-------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempTechnicalTrunkMaster') )
			Drop table #TempTechnicalTrunkMaster

		select TrunkID , Trunk
		into #TempTechnicalTrunkMaster
		from ReferenceServer.UC_Reference.dbo.tb_Trunk
		where trunkTypeID <> 9

		-------------------
		-- COMMERCIAL TRUNK
		-------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCommercialTrunkMaster') )
			Drop table #TempCommercialTrunkMaster

		select TrunkID , Trunk
		into #TempCommercialTrunkMaster
		from ReferenceServer.UC_Reference.dbo.tb_Trunk
		where trunkTypeID = 9

		----------------
		-- DESTINATION
		----------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDestinationMaster') )
			Drop table #TempDestinationMaster

		select Destination , DestinationID
		into #TempDestinationMaster
		from ReferenceServer.UC_Reference.dbo.tb_Destination

		--------------
		-- COUNTRY
		--------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCountryMaster') )
			Drop table #TempCountryMaster

		select CountryID , Country
		into #TempCountryMaster
		from ReferenceServer.UC_Reference.dbo.tb_Country

		------------------
		-- SERVICE LEVEL
		------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempServiceLevelMaster') )
			Drop table #TempServiceLevelMaster

		select ServiceLevelID , ServiceLevel
		into #TempServiceLevelMaster
		from ReferenceServer.UC_Reference.dbo.tb_ServiceLevel

		---------------
		-- CALL TYPE
		---------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCallTypeMaster') )
			Drop table #TempCallTypeMaster

		select CalltypeID , CallType
		into #TempCallTypeMaster
		from ReferenceServer.UC_Reference.dbo.tb_CallType

		-------------------
		-- CHARGE TYPE
		-------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempChargeTypeMaster') )
			Drop table #TempChargeTypeMaster

		select ChargeTypeID , ChargeType
		into #TempChargeTypeMaster
		from ReferenceServer.UC_Reference.dbo.tb_ChargeType

		----------------
		-- RATE PLAN
		---------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempRatePlanMaster') )
			Drop table #TempRatePlanMaster

		select RatePlanID , RatePlan
		into #TempRatePlanMaster
		from ReferenceServer.UC_Reference.dbo.tb_RatePlan

		---------------
		-- CURRENCY
		----------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCurrencyMaster') )
			Drop table #TempCurrencyMaster

		select CurrencyID , Currency
		into #TempCurrencyMaster
		from ReferenceServer.UC_Reference.dbo.tb_Currency

		-------------------
		-- NUMBERPLAN
		-------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempNumberPlanMaster') )
			Drop table #TempNumberPlanMaster

		select NumberPlanID , NumberPlan
		into #TempNumberPlanMaster
		from ReferenceServer.UC_Reference.dbo.tb_NumberPlan

		----------
		-- RATE
		----------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempRateMaster') )
			Drop table #TempRateMaster

		select rt.RateID , rt.BeginDate , rt.EndDate , rtd.Rate , rtd.RatetypeID
		into #TempRateMaster
		from ReferenceServer.UC_Reference.dbo.tb_Rate rt
		inner join ReferenceServer.UC_Reference.dbo.tb_RateDetail rtd on rt.RateID = rtd.RateID

		-------------------
		-- RATING METHOD
		------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempRatingMethodMaster') )
			Drop table #TempRatingMethodMaster

		select RatingMethodID , RatingMethod
		into #TempRatingMethodMaster
		from ReferenceServer.UC_Reference.dbo.tb_RatingMethod

		----------------------
		-- DATE TIME BAND
		---------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDateTimeBandMaster') )
			Drop table #TempDateTimeBandMaster

		select tbl3.RateDimensionTemplateID , tbl3.RateDimensionTemplate,
			tbl2.RateDimensionBandID as DateTimeBandID , tbl2.RateDimensionBand as DateTimeBand,
			tbl1.RatingMethodID , tbl1.RateItemID
		into #TempDateTimeBandMaster
		from ReferenceServer.UC_Reference.dbo.tb_RateNumberIdentifier tbl1
		inner join ReferenceServer.UC_Reference.dbo.tb_RateDimensionBand tbl2 on tbl1.RateDimension1BandID = tbl2.RateDimensionBandID
		inner join ReferenceServer.UC_Reference.dbo.tb_RateDimensionTemplate tbl3 on tbl2.RateDimensionTemplateID = tbl3.RateDimensionTemplateID
		where tbl3.RateDimensionID = 1

		---------------------------
		-- CDR File name Registry
		---------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCDRFileRegistryMaster') )
			Drop table #TempCDRFileRegistryMaster

		select ObjectInstanceID , ObjectInstance
		into #TempCDRFileRegistryMaster
		from ReferenceServer.UC_Operations.dbo.tb_ObjectInstance tbl1
		inner join ReferenceServer.UC_Operations.dbo.tb_Object tbl2 on tbl1.ObjectID = tbl2.ObjectID
		where tbl2.ObjectTypeID = 100 -- CDR File Upload

End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!! While collecting master reference data for extract. ' + ERROR_MESSAGE()
	set @ResultFlag = 1
	GOTO ENDPROCESS

End Catch

----------------------------------------------------------------------------
-- Process through the start and end dates to establish the period for which
-- results need to extracted
----------------------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAllDateRange ') )
		Drop table #TempAllDateRange 

Create table #TempAllDateRange (CallDate datetime)

While ( @BeginDate <= @EndDate )
Begin

		insert into #TempAllDateRange values (@BeginDate)
		set @BeginDate = DateAdd(dd , 1 , @BeginDate)

End

------------------------------------------
-- Start of Extraction Process Section
------------------------------------------

Declare  @SQLString nvarchar(2000),
	     @ParamDefinition nvarchar(2000),
         @TableExists int,
		 @ExtractTransitCount int,
		 @ExtractFinalCount int

DECLARE @CDR_Table_Name varchar(100),
        @Sys_Table_Name varchar(100), 
        @FTR_Table_Name varchar(100),
		@Data_Table_Name varchar(100), 
        @CDR_Partition varchar(100)

Declare @SelectClause nvarchar(max),
        @SchemaClause nvarchar(max),
		@DisplayClause nvarchar(max),
		@InsertClause nvarchar(max),
		@SQLStr nvarchar(max),
		@FTRInfoFlag int ,
	    @ExtractTableName varchar(100),
		@ExtractTableNameFinal varchar(100),
		@AllMultiSelectParamFlag int


if (
		@AllCountryFlag= 1 and
        @AllServiceLevelFlag = 1 and
		@AllDestinationFlag = 1 and
		@INAllAccountFlag = 1 and
		@INAllCommercialTrunkFlag = 1 and
		@INAllTechnicalTrunkFlag = 1 and
		@OUTAllAccountFlag = 1 and
		@OUTAllCommercialTrunkFlag = 1 and
		@OUTAllTechnicalTrunkFlag = 1
   )
Begin

		set @AllMultiSelectParamFlag = 1

End


set @ExtractTableName = 'tb_CDRExtract_' + replace(replace(replace(convert(varchar(20) , getdate() , 120 ) , '-' , ''), ':' , ''), ' ' , '')

if exists ( select 1 from sysobjects where name = @ExtractTableName and xtype = 'U' )
    Exec ( 'Drop table ' + @ExtractTableName )

----------------------------------------------------------
-- Establish if user has requested any FTR information
-- in the extract fields
----------------------------------------------------------

if exists (
				select 1
				from #TempDisplayFieldIDTable tbl1
				inner join tb_CDRExtractMasterReference tbl2 on
				               tbl1.DisplayFieldID = tbl2.CDRExtractMasterReferenceID
                where tbl2.DataExtractSchema = 'FTR'
          )
Begin

		set @FTRInfoFlag = 1

End

Else
Begin

		set @FTRInfoFlag = 0

End

------------------------------------------------------------
-- Call the procedure to prepare the Display, Extract and 
-- Join Clause strings for the final dynalic SQL query
------------------------------------------------------------

Begin Try

	set @ErrorDescription = NULL
	set @ResultFlag = 0

	Exec SP_BSCDRExtractDataPrepare @SelectClause Output,
	                                @InsertClause Output,
                                    @SchemaClause Output,
		                            @DisplayClause Output,
									@ErrorDescription Output,
									@ResultFlag Output

	if ( @ResultFlag = 1 )
	Begin
			
		set @ResultFlag = 1
		GOTO ENDPROCESS

	End 

End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!! Preparing Display , Extract and Join Clause dynamic data. ' + ERROR_MESSAGE()
	set @ResultFlag = 1
	GOTO ENDPROCESS

End Catch

--select @SelectClause , @InsertClause , @SchemaClause , @DisplayClause

if ( @ConditionClause is NULL )
Begin
        set @ConditionClauseOptimize = ''
		GOTO PREPAREDYNAMICSQL
End

------------------------------------------------------------
-- Call the procedure to Check the Condition clause and
-- optimize it as per the dynamic SQL
------------------------------------------------------------

Begin Try

	set @ErrorDescription = NULL
	set @ResultFlag = 0

	Exec SP_BSCDRExtractOptimizeConditionClause @ConditionClause ,
											    @ConditionClauseOptimize Output,
												@ErrorDescription Output,
												@ResultFlag Output

	if ( @ResultFlag = 1 )
	Begin
			
		set @ResultFlag = 1
		GOTO ENDPROCESS

	End 

End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!! While optimizing the condition clause. ' + ERROR_MESSAGE()
	set @ResultFlag = 1
	GOTO ENDPROCESS

End Catch

--select @ConditionClauseOptimize


PREPAREDYNAMICSQL:

DECLARE db_populate_ra_det CURSOR FOR  
select tbl2.ServerAlias + '.' + tbl3.DatabaseName + '.dbo.tb_eer_' +
       right(convert(varchar(4) ,year(CallDate)), 2) + 
	   right(('0' + convert(varchar(2) ,Month(CallDate))),2) + 
	   right(('0' + convert(varchar(2) ,DatePart(dd ,CallDate))),2) ,
	   tbl2.ServerAlias + '.' + tbl3.DatabaseName + '.dbo.sysobjects',
      tbl2.ServerAlias + '.' + tbl3.DatabaseName +'.dbo.tb_ftr_' +
       right(convert(varchar(4) ,year(CallDate)), 2) + 
	   right(('0' + convert(varchar(2) ,Month(CallDate))),2) + 
	   right(('0' + convert(varchar(2) ,DatePart(dd ,CallDate))),2),
	   'tb_eer_' +
       right(convert(varchar(4) ,year(CallDate)), 2) + 
	   right(('0' + convert(varchar(2) ,Month(CallDate))),2) + 
	   right(('0' + convert(varchar(2) ,DatePart(dd ,CallDate))),2)
from REFERENCESERVER.UC_Operations.dbo.tb_ServerDatabase tbl1
inner join  REFERENCESERVER.UC_Operations.dbo.tb_Server tbl2 on tbl1.ServerID = tbl2.ServerID
inner join REFERENCESERVER.UC_Operations.dbo.tb_Database tbl3 on tbl1.DatabaseID = tbl3.DatabaseID
cross join #TempAllDateRange tbl4

OPEN db_populate_ra_det
FETCH NEXT FROM db_populate_ra_det
INTO @CDR_Table_Name  , @Sys_Table_Name , @FTR_Table_Name  , @Data_Table_Name 

WHILE @@FETCH_STATUS = 0   
BEGIN   
       
		BEGIN Try

			----------------------------------------------------------------------
			-- Build the SQL command for calling to check if the summary table
            -- exists or not
			-----------------------------------------------------------------------
		
			Set @SQLString=N'Select @param = count(*) from ' + @Sys_Table_Name + ' where name = ''' + @Data_Table_Name  + ''' and xtype = ''u'''

			SET @ParamDefinition=N'@param int OUTPUT'

			----------------------------------------------
			-- Execute the stored procedure dynamically
			----------------------------------------------

			EXECUTE sp_executesql
				@SQLString,
				@ParamDefinition,
				@param=@TableExists  OUTPUT

				--select @CDR_Table_Name , @FTR_Table_Name , @Sys_Table_Name , @TableExists

             if ( @TableExists  = 0 )
                GOTO NEXTREC	
			
			------------------------------------------------------------
			-- Construct the dynamic SQL to extract the data records
			------------------------------------------------------------

			if not exists ( select 1 from sysobjects where name = @ExtractTableName and xtype = 'U' )
			Begin

					set @SQLStr = 'Select ' + @InsertClause + char(10)+
					              'into ' + @ExtractTableName + char(10) +
								  'from ' + @CDR_Table_Name + ' tbl1' + char(10) +
								  Case
								      When @FTRInfoFlag = 1 then
									  		  'left join ' + @FTR_Table_Name + ' tbl2 on ' + char(10) +
											  '    tbl1.ObjectInstanceID = tbl2.ObjectInstanceID ' + char(10) +
											  '   and ' + char(10) +
											  '	   tbl1.BERID = tbl2.BERID ' + char(10) +
											  '	and ' + char(10) +
											  '   tbl2.DirectionID = 1 ' + char(10)
                                       Else ''
								  End +
								  Case
								      When @FTRInfoFlag = 1 then
									  		  'left join ' + @FTR_Table_Name + ' tbl3 on ' + char(10) +
											  '    tbl1.ObjectInstanceID = tbl3.ObjectInstanceID ' + char(10) +
											  '   and ' + char(10) +
											  '	   tbl1.BERID = tbl3.BERID ' + char(10) +
											  '	and ' + char(10) +
											  '   tbl3.DirectionID = 2 ' + char(10)
                                       Else ''
								  End +
								  @SchemaClause + char(10) 

			End

			Else
			Begin

					set @SQLStr = 'Insert into ' + @ExtractTableName + char(10) +
					              'Select ' + @SelectClause + char(10)+					              
								  'from ' + @CDR_Table_Name + ' tbl1' + char(10) +
								  Case
								      When @FTRInfoFlag = 1 then
									  		  'left join ' + @FTR_Table_Name + ' tbl2 on ' + char(10) +
											  '    tbl1.ObjectInstanceID = tbl2.ObjectInstanceID ' + char(10) +
											  '   and ' + char(10) +
											  '	   tbl1.BERID = tbl2.BERID ' + char(10) +
											  '	and ' + char(10) +
											  '   tbl2.DirectionID = 1 ' + char(10)
                                       Else ''
								  End +
								  Case
								      When @FTRInfoFlag = 1 then
									  		  'left join ' + @FTR_Table_Name + ' tbl3 on ' + char(10) +
											  '    tbl1.ObjectInstanceID = tbl3.ObjectInstanceID ' + char(10) +
											  '   and ' + char(10) +
											  '	   tbl1.BERID = tbl3.BERID ' + char(10) +
											  '	and ' + char(10) +
											  '   tbl3.DirectionID = 2 ' + char(10)
                                       Else ''
								  End +
								  @SchemaClause + char(10) 

			End

			set @SQLStr = @SQLStr + char(10) + ' Where 1 = 1' + char(10) +
					Case
						When @INAllAccountFlag = 1 then ''
						Else ' and tbl1.INAccountID in (' + @INAccountIDList + ')' + char(10)
					End + 
					Case
						When @OUTAllAccountFlag = 1 then ''
						Else ' and tbl1.OUTAccountID in (' + @OUTAccountIDList + ')' + char(10)
					End + 
					Case
						When  @AllServiceLevelFlag = 1 then ''
						Else ' and tbl1.INServiceLevelID in (' + @ServiceLevelIDList + ')' + char(10)
					End +
					Case
						When  @AllDestinationFlag  = 1 then ''
						Else ' and tbl1.RoutingDestinationID in (' + @DestinationIDList + ')' + char(10)
					End +
					Case
						When  @AllCountryFlag = 1 then ''
						Else ' and tbl1.RoutingCountryID in (' + @CountryIDList + ')' + char(10)
					End +
					Case
						When  @INAllCommercialTrunkFlag  = 1 then ''
						Else ' and tbl1.INCommercialTrunkID in (' + @INCommercialTrunkIDList + ')' + char(10)
					End +
					Case
						When  @OUTAllCommercialTrunkFlag  = 1 then ''
						Else ' and tbl1.OUTCommercialTrunkID in (' + @OUTCommercialTrunkIDList + ')' + char(10) 
					End +
					Case
						When  @INAllTechnicalTrunkFlag   = 1 then ''
						Else ' and tbl1.INTrunkID in (' + @INTechnicalTrunkIDList + ')' + char(10)
					End +
					Case
						When  @OUTAllTechnicalTrunkFlag   = 1 then ''
						Else ' and tbl1.OUTTrunkID in (' + @OUTTechnicalTrunkIDList + ')' + char(10)
					End


              --------------------------------------------------------
			  -- If none of the multi select parameters are selected
			  -- then apply the condition clause to prevent extraction
			  -- of huge number of data records
			  ---------------------------------------------------------

			  if ( ( @AllMultiSelectParamFlag = 1 ) and (@ConditionClauseOptimize <> '') )
			  Begin

					set @SQLStr = @SQLStr + char(10) + ' and ' + @ConditionClauseOptimize

			  End
			  
			  --print @SQLStr
			  
			  Exec (@SQLStr)

			  ------------------------------------------------
			  -- Check the number of records in the transit
			  -- extract table, and if they are more than
			  -- 200,000 then move the contents to the final
			  -- extract
			  ---------------------------------------------------

			 Set @SQLString=N'Select @param = count(*) from ' + @ExtractTableName

			 SET @ParamDefinition=N'@param int OUTPUT'

			EXECUTE sp_executesql
				@SQLString,
				@ParamDefinition,
				@param=@ExtractTransitCount  OUTPUT	
				
			--select @ExtractTransitCount	as ExtractTransitCount

             if ( @ExtractTransitCount > 200000 )
			 Begin


						-------------------------------------------------------
						-- Check if the Final extract table exists or not.
						-- Create the table in case it is not there
						--------------------------------------------------------

						set @ExtractTableNameFinal = @ExtractTableName + '_Final'

						if not exists ( select 1 from sysobjects where name = @ExtractTableNameFinal and xtype = 'U' )
						Begin

							    set @SQLStr = 'Select * into ' + @ExtractTableNameFinal +
									            ' from ' + @ExtractTableName + 
												' where 1 = 2'
									 
									--print @SQLStr
									            
									Exec (@SQLStr)


						End

						---------------------------------------------------
						-- Insert records into the final extract table by
						-- applying the condition clause
						---------------------------------------------------

						set @SQLStr = 'Insert into ' + @ExtractTableNameFinal +
							            ' select * from ' +  @ExtractTableName +
										Case
											When @ConditionClause is NULL then ''
											Else ' where ' + @ConditionClause
										End
										

						--print @SQLStr
										            
						Exec(@SQLStr)

						-------------------------------------------------
						-- Delete all the records from the transit table
						--------------------------------------------------

						Exec ('Delete from ' + @ExtractTableName)												 


			 End             
			      
	      						   
		 END Try  
	     
		 BEGIN Catch
	     
				set @ErrorDescription = 'ERROR !!! While extracting CDR records from database. ' + ERROR_MESSAGE()
				set @ResultFlag = 1

          
				CLOSE db_populate_ra_det  
				DEALLOCATE db_populate_ra_det 
				
				GOTO ENDPROCESS  
	     
		 End Catch
	     
		 --print @SQLStr

       NEXTREC:
	 
	   FETCH NEXT FROM db_populate_ra_det
	   INTO @CDR_Table_Name  , @Sys_Table_Name , @FTR_Table_Name  , @Data_Table_Name  
 
END  

CLOSE db_populate_ra_det  
DEALLOCATE db_populate_ra_det 

-------------------------------------------------------
-- Execution of this logic means that the CDR records
-- for complete extract requirements have been executed.
-- Now we need to transfer the data from the transit to
-- final table based on whether condition clause is
-- there or not
--------------------------------------------------------

set @ExtractTableNameFinal = @ExtractTableName + '_Final'

if not exists ( select 1 from sysobjects where name = @ExtractTableNameFinal and xtype = 'U' )
Begin

		set @SQLStr = 'Select * into ' + @ExtractTableNameFinal +
						' from ' + @ExtractTableName + 
						' where 1 = 2'
									 
			--print @SQLStr
									            
			Exec (@SQLStr)


End


---------------------------------------------------
-- Insert records into the final extract table by
-- applying the condition clause
---------------------------------------------------

set @SQLStr = 'Insert into ' + @ExtractTableNameFinal +
				' select * from ' +  @ExtractTableName +
				Case
					When @ConditionClause is NULL then ''
					Else ' where ' + @ConditionClause
				End

--print @SQLStr
										            
Exec(@SQLStr)
												 


----------------------------------------------------------
-- Get the count of total number of CDR records Extracted
----------------------------------------------------------

Set @SQLString=N'Select @param = count(*) from ' + @ExtractTableNameFinal

SET @ParamDefinition=N'@param int OUTPUT'

EXECUTE sp_executesql
@SQLString,
@ParamDefinition,
@param=@ExtractFinalCount  OUTPUT
							
set @ErrorDescription = 'Total number of records extracted : (' + convert(varchar(100) , @ExtractFinalCount) + ')'

PUBLISHEXTRACTTOFILE:

------------------------------------------------------------------
-- Export the data from the Extract table into an Output File
-- at the desired location
------------------------------------------------------------------

---------------------------------------------------------------
-- Error out indicating that no data has been extracted for
-- selected criteria, in case the extract table has count
-- as 0
---------------------------------------------------------------

if not exists ( 
				 SELECT 1 FROM SYSOBJECTS SYS_OBJ, SYSINDEXES SYS_INDX
				 WHERE SYS_INDX.ID = SYS_OBJ.ID AND INDID IN(0,1)
				 and SYS_OBJ.NAME  = @ExtractTableNameFinal
				 and SYS_INDX.ROWCNT > 0
              ) 
Begin

        set @ErrorDescription = 'ERROR !!!! No data has been extracted for the selected CDR extract parameters'
        set @ResultFlag  = 1
        GOTO ENDPROCESS

End

Declare @ReportExtractPath  varchar(500),
        @HeaderFile varchar(500),
		@RecordFile varchar(500),
        @ExtractHeader nvarchar(max) ,
		@QualifiedTableName varchar(200),
		@Command varchar(2000),
		@FileExists int,
		@Result int

set @ExtractHeader = 'echo ' + replace(replace(@DisplayClause , ',' , '^|'), char(10) , '') + ' > '

--------------------------------------------------------------
-- Get the CDR Extract Folder where file needs to be created
--------------------------------------------------------------

select @ReportExtractPath = ConfigValue 
from ReferenceServer.UC_Admin.dbo.tb_Config
where ConfigName = 'CDRExtractPath'
and AccessScopeID = -8 -- BI Reporting

if (@ReportExtractPath is NULL )
Begin
	    
    set @ErrorDescription = 'ERROR !!!! CDR Extract Creation Folder (CDRExtractPath) not configured in tb_Config'
    set @ResultFlag  = 1
    GOTO ENDPROCESS

End

Set @QualifiedTableName = db_name() + '.dbo.' + @ExtractTableNameFinal

if (right(@ReportExtractPath , 1) <> '\')
	set @ReportExtractPath = @ReportExtractPath + '\'

set @HeaderFile = @ReportExtractPath + @ExtractTableName + '_Header.txt'
set @RecordFile = @ReportExtractPath + @ExtractTableName + '_RecordData.txt'
set @CDRExtractFileName = @ReportExtractPath + @ExtractTableName + '.txt'

Begin Try

    --------------------------------------------------------
	-- Create the Header file for the CDR extract export file
	---------------------------------------------------------

	set  @Command = @ExtractHeader + '"' + @HeaderFile + '"'

	--print @Command

    exec @Result = master..xp_cmdshell @Command

    IF @Result <> 0
    Begin
	    
        set @ErrorDescription = 'ERROR !!!! Failed to create Header file for CDR Extract Export'
        set @ResultFlag  = 1
        GOTO ENDPROCESS

    End

	set @FileExists = 0

	Exec master..xp_fileexist @HeaderFile , @FileExists output  

	if ( @FileExists <> 1 )
	Begin

		set @ErrorDescription = 'ERROR !!!! Failed to create Header file for CDR Extract Export'
		set @ErrorDescription  = 1
		GOTO ENDPROCESS

	End 

    ---------------------------
    -- Create the Record File.
    --------------------------- 

    SET @Command = 'bcp "SELECT * from ' + @QualifiedTableName +'" queryout ' + ltrim(rtrim(@RecordFile)) + ' -c -t "|" -r"\n" -T -S '+ @@servername
    
	--print @Command 

    exec @Result = master..xp_cmdshell @Command

    IF @Result <> 0
    Begin	

        set @ErrorDescription = 'ERROR !!!! Failed to create Record File for CDR Extract Export'
        set @ResultFlag  = 1
        GOTO ENDPROCESS
    
    End

	set @FileExists = 0

	Exec master..xp_fileexist @RecordFile , @FileExists output  

	if ( @FileExists <> 1 )
	Begin

		set @ErrorDescription = 'ERROR !!!! Failed to create Record File for CDR Extract Export'
		set @ErrorDescription  = 1
		GOTO ENDPROCESS

	End 

    -----------------------------------------------
    -- Create the Final Extract file
    -----------------------------------------------

    set @Command = 'copy '+ @HeaderFile + ' + ' + @RecordFile + ' '+ @CDRExtractFileName + ' /B'
    --print @Command 
    exec master..xp_cmdshell @Command 

	---------------------------------------------------
	-- Delete the intermediary header and record file
	---------------------------------------------------

    set @Command = 'del '+ @HeaderFile
    exec master..xp_cmdshell @Command 

    set @Command = 'del '+ @RecordFile
    exec master..xp_cmdshell @Command  

	------------------------------------------------
	-- Check if the extract has been created or not 
	------------------------------------------------

	set @FileExists = 0

	Exec master..xp_fileexist @CDRExtractFileName , @FileExists output  

	if ( @FileExists <> 1 )
	Begin

		set @ErrorDescription = 'Error !!! CDR Extract Export file not created'
		set @ErrorDescription  = 1
		GOTO ENDPROCESS

	End 

End Try

Begin Catch

	set @ErrorDescription = 'ERROR !!! Exporting Extract data into file. ' + ERROR_MESSAGE()
	set @ResultFlag = 1
	GOTO ENDPROCESS

End Catch

ENDPROCESS:

select @ErrorDescription

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAccountMaster') )
		Drop table #TempAccountMaster

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempSwitchMaster') )
		Drop table #TempSwitchMaster

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempTechnicalTrunkMaster') )
		Drop table #TempTechnicalTrunkMaster

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDestinationMaster') )
		Drop table #TempDestinationMaster

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempServiceLevelMaster') )
		Drop table #TempServiceLevelMaster

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCountryMaster') )
		Drop table #TempCountryMaster

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCallTypeMaster') )
		Drop table #TempCallTypeMaster

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempChargeTypeMaster') )
		Drop table #TempChargeTypeMaster

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempRatePlanMaster') )
		Drop table #TempRatePlanMaster

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempRateMaster') )
		Drop table #TempRateMaster

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempRatingMethodMaster') )
		Drop table #TempRatingMethodMaster

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDateTimeBandMaster') )
		Drop table #TempDateTimeBandMaster

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCDRFileRegistryMaster') )
		Drop table #TempCDRFileRegistryMaster

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDisplayFieldIDTable') )
		Drop table #TempDisplayFieldIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempINAccountIDTable') )
		Drop table #TempINAccountIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempOUTAccountIDTable') )
		Drop table #TempOUTAccountIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempINCommercialTrunkIDTable') )
		Drop table #TempINCommercialTrunkIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempOUTCommercialTrunkIDTable') )
		Drop table #TempOUTCommercialTrunkIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempINTechnicalTrunkIDTable') )
		Drop table #TempINTechnicalTrunkIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempOUTTechnicalTrunkIDTable') )
		Drop table #TempOUTTechnicalTrunkIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCountryIDTable') )
		Drop table #TempCountryIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempServiceLevelIDTable') )
		Drop table #TempServiceLevelIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDestinationIDTable') )
		Drop table #TempDestinationIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempExtractResultSet') )
		Drop table #TempExtractResultSet

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAllDateRange ') )
		Drop table #TempAllDateRange 

if exists ( select 1 from sysobjects where name = @ExtractTableName and xtype = 'U' )
    Exec ( 'Drop table ' + @ExtractTableName )

if exists ( select 1 from sysobjects where name = @ExtractTableNameFinal and xtype = 'U' )
    Exec ( 'Drop table ' + @ExtractTableNameFinal )
GO
