USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_RPTCostRevenueASRMonthlyReportTabular]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_RPTCostRevenueASRMonthlyReportTabular]
(
     @ReportID int,
	 @StartMonth int,
	 @EndMonth int,  
	 @CallTypeID int,
	 @AccountIDList nvarchar(max), 
	 @CommercialTrunkIDList nvarchar(max),
	 @TechnicalTrunkIDList nvarchar(max),
	 @CountryIDList nvarchar(max),
	 @DestinationIDList nvarchar(max),
 	 @ServiceLevelIDList nvarchar(max),
	 @DestinationGroupIDList nvarchar(max),
	 @Level1Param varchar(100),
	 @Level2Param varchar(100),
	 @Level3Param varchar(100),
	 @Level4Param varchar(100),
	 @TotalResult nvarchar(max) Output,
 	 @ErrorDescription varchar(2000) Output,
	 @ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @AllCountryFlag int = 0,
        @AllServiceLevelFlag int = 0,
		@AllDestinationFlag int = 0,
		@AllAccountFlag int = 0,
		@AllCommercialTrunkFlag int = 0,
		@AllTechnicalTrunkFlag int = 0,
		@AllDestinationGroupFlag int = 0,
		@SQLStr1 nvarchar(max),
		@SQLStr2 nvarchar(max),
		@SQLStr3 nvarchar(max),
		@SQLStr  nvarchar(max),
		@StartDate datetime,
		@EndDate datetime

---------------------------------------------------------
-- Check if the Report is valid and exists in he system
---------------------------------------------------------

if not exists ( select 1 from tb_Report where ReportID = @ReportID and Flag & 1 <> 1 )
Begin

		set @ErrorDescription = 'ERROR !!! Report ID is not valid or is not active (flag <> 0)'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End

----------------------------------------------------
-- Set the start date for use in future processing
----------------------------------------------------

set @StartDate = convert(datetime ,
							Substring(convert(varchar(20) , @StartMonth) , 1,4) + '-' + 
							substring(convert(varchar(20) , @StartMonth) , 5,2) + '-' + '01'
						)

-------------------------------------------------------------------
-- Check if the different Level parameters are valid and are part
-- of the summarization parameters for this report 
-------------------------------------------------------------------

Declare @Level1ParamID int,
        @Level2ParamID int,
		@Level3ParamID int,
		@Level4ParamID int

Declare @Level1ParamValue varchar(100),
        @Level2ParamValue varchar(100),
		@Level3ParamValue varchar(100),
		@Level4ParamValue varchar(100)

Declare @Level1ParamFormat varchar(100),
        @Level2ParamFormat varchar(100),
		@Level3ParamFormat varchar(100),
		@Level4ParamFormat varchar(100)

if ( (@Level1Param is NOT NULL) )
Begin

	select @Level1ParamID = RptSummarizeParameterID,
	       @Level1ParamValue = RPTSummarizeParameterValue,
		   @Level1ParamFormat = RPTSummarizeParameterFormat
	from tb_RptSummarizeParameter
	where RptSummarizeParameterName = @Level1Param
	and flag & 1 <> 1

	if ( @Level1ParamID is NULL )
	Begin
			set @ErrorDescription = 'ERROR !!! Level 1 parameter : ' + @Level1Param + ' is not valid'
			set @ResultFlag = 1
			GOTO ENDPROCESS
	End

	if not exists ( select 1 from tb_ReportParam where ReportID = @ReportID and ParameterID = @Level1ParamID and flag & 1 <> 1 )
	Begin
			set @ErrorDescription = 'ERROR !!! Level 1 parameter : ' + @Level1Param + ' is not valid for this report'
			set @ResultFlag = 1
			GOTO ENDPROCESS

	End

End

if ( (@Level2Param is NOT NULL) )
Begin

	select @Level2ParamID = RptSummarizeParameterID,
	       @Level2ParamValue = RPTSummarizeParameterValue,
		   @Level2ParamFormat = RPTSummarizeParameterFormat
	from tb_RptSummarizeParameter
	where RptSummarizeParameterName = @Level2Param
	and flag & 1 <> 1

	if ( @Level2ParamID is NULL )
	Begin
			set @ErrorDescription = 'ERROR !!! Level 2 parameter : ' + @Level2Param + ' is not valid'
			set @ResultFlag = 1
			GOTO ENDPROCESS
	End

	if not exists ( select 1 from tb_ReportParam where ReportID = @ReportID and ParameterID = @Level2ParamID and flag & 1 <> 1 )
	Begin
			set @ErrorDescription = 'ERROR !!! Level 2 parameter : ' + @Level2Param + ' is not valid for this report'
			set @ResultFlag = 1
			GOTO ENDPROCESS

	End

End

if ( (@Level3Param is NOT NULL) )
Begin

	select @Level3ParamID = RptSummarizeParameterID,
	       @Level3ParamValue = RPTSummarizeParameterValue,
		   @Level3ParamFormat = RPTSummarizeParameterFormat
	from tb_RptSummarizeParameter
	where RptSummarizeParameterName = @Level3Param
	and flag & 1 <> 1

	if ( @Level3ParamID is NULL )
	Begin
			set @ErrorDescription = 'ERROR !!! Level 3 parameter : ' + @Level3Param + ' is not valid'
			set @ResultFlag = 1
			GOTO ENDPROCESS
	End

	if not exists ( select 1 from tb_ReportParam where ReportID = @ReportID and ParameterID = @Level3ParamID and flag & 1 <> 1 )
	Begin
			set @ErrorDescription = 'ERROR !!! Level 3 parameter : ' + @Level3Param + ' is not valid for this report'
			set @ResultFlag = 1
			GOTO ENDPROCESS

	End

End


if ( (@Level4Param is NOT NULL) )
Begin

	select @Level4ParamID = RptSummarizeParameterID,
	       @Level4ParamValue = RPTSummarizeParameterValue,
		   @Level4ParamFormat = RPTSummarizeParameterFormat
	from tb_RptSummarizeParameter
	where RptSummarizeParameterName = @Level4Param
	and flag & 1 <> 1

	if ( @Level4ParamID is NULL )
	Begin
			set @ErrorDescription = 'ERROR !!! Level 4 parameter : ' + @Level4Param + ' is not valid'
			set @ResultFlag = 1
			GOTO ENDPROCESS
	End

	if not exists ( select 1 from tb_ReportParam where ReportID = @ReportID and ParameterID = @Level4ParamID and flag & 1 <> 1 )
	Begin
			set @ErrorDescription = 'ERROR !!! Level 3 parameter : ' + @Level4Param + ' is not valid for this report'
			set @ResultFlag = 1
			GOTO ENDPROCESS

	End

End


-------------------------------------------------------------
-- Set the CALL TYPE to NULL in case the value passed is 0
-- indicating that all CALL TYPES need to be considered
-------------------------------------------------------------

if ( @CallTypeID = 0 )
	set @CallTypeID = NULL

--Select 'Step 1..' , getdate()

Begin Try

-----------------------------------------------------------------
-- Create table for list of selected Accounts from the parameter
-- passed
-----------------------------------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAccountIDTable') )
				Drop table #TempAccountIDTable

		Create Table #TempAccountIDTable (AccountID varchar(100) )


		insert into #TempAccountIDTable
		select * from FN_ParseValueList ( @AccountIDList )

		----------------------------------------------------------------
		-- Check to ensure that none of the values are non numeric
		----------------------------------------------------------------

		if exists ( select 1 from #TempAccountIDTable where ISNUMERIC(AccountID) = 0 )
		Begin

			set @ErrorDescription = 'ERROR !!! List of Account IDs passed contain a non numeric value'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End

		------------------------------------------------------
		-- Check if the All the Accounts have been selected 
		------------------------------------------------------

		if exists (
						select 1 
						from #TempAccountIDTable 
						where AccountID = 0
				  )
		Begin

                  set @AllAccountFlag = 1
				  GOTO PROCESSCOMMERCIALTRUNK
				  
		End
		
        -----------------------------------------------------------------
		-- Check to ensure that all the Account IDs passed are valid values
		-----------------------------------------------------------------
		
		if exists ( 
						select 1 
						from #TempAccountIDTable 
						where AccountID not in
						(
							Select AccountID
							from ReferenceServer.UC_Reference.dbo.tb_Account
							where flag & 1 <> 1
						)
					)
		Begin

			set @ErrorDescription = 'ERROR !!! List of Account IDs passed contain value(s) which are not valid or do not exist'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End

PROCESSCOMMERCIALTRUNK:

-----------------------------------------------------------------
-- Create table for list of selected Commercial Trunks from the 
-- parameter passed
-----------------------------------------------------------------
		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCommercialTrunkIDTable') )
				Drop table #TempCommercialTrunkIDTable

		Create table #TempCommercialTrunkIDTable (CommercialTrunkID varchar(100) )


		insert into #TempCommercialTrunkIDTable
		select * from FN_ParseValueList ( @CommercialTrunkIDList )

		----------------------------------------------------------------
		-- Check to ensure that none of the values are non numeric
		----------------------------------------------------------------

		if exists ( select 1 from #TempCommercialTrunkIDTable where ISNUMERIC(CommercialTrunkID) = 0 )
		Begin

			set @ErrorDescription = 'ERROR !!! List of CommercialTrunk IDs passed contain a non numeric value'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End

		------------------------------------------------------
		-- Check if the All the CommercialTrunks have been selected 
		------------------------------------------------------

		if exists (
						select 1 
						from #TempCommercialTrunkIDTable 
						where CommercialTrunkID = 0
				  )
		Begin

                  set @AllCommercialTrunkFlag = 1
				  GOTO PROCESSTRUNK
				  
		End
		
        -----------------------------------------------------------------
		-- Check to ensure that all the CommercialTrunk IDs passed are valid values
		-----------------------------------------------------------------
		
		if exists ( 
						select 1 
						from #TempCommercialTrunkIDTable 
						where CommercialTrunkID not in
						(
							Select TrunkID
							from ReferenceServer.UC_Reference.dbo.tb_Trunk
							where trunktypeID = 9 -- Commercial trunk
							and flag & 1 <> 1
						)
					)
		Begin

			set @ErrorDescription = 'ERROR !!! List of CommercialTrunk IDs passed contain value(s) which are not valid or do not exist'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End

PROCESSTRUNK:

-----------------------------------------------------------------
-- Create table for list of selected Technical Trunks from the 
-- parameter passed
-----------------------------------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempTechnicalTrunkIDTable') )
				Drop table #TempTechnicalTrunkIDTable

		Create table #TempTechnicalTrunkIDTable (TechnicalTrunkID varchar(100) )


		insert into #TempTechnicalTrunkIDTable
		select * from FN_ParseValueList ( @TechnicalTrunkIDList )

		----------------------------------------------------------------
		-- Check to ensure that none of the values are non numeric
		----------------------------------------------------------------

		if exists ( select 1 from #TempTechnicalTrunkIDTable where ISNUMERIC(TechnicalTrunkID) = 0 )
		Begin

			set @ErrorDescription = 'ERROR !!! List of TechnicalTrunk IDs passed contain a non numeric value'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End

		------------------------------------------------------
		-- Check if the All the TechnicalTrunks have been selected 
		------------------------------------------------------

		if exists (
						select 1 
						from #TempTechnicalTrunkIDTable 
						where TechnicalTrunkID = 0
				  )
		Begin

                  set @AllTechnicalTrunkFlag = 1
				  GOTO PROCESSCOUNTRY
				  
		End
		
        -----------------------------------------------------------------
		-- Check to ensure that all the TechnicalTrunk IDs passed are valid values
		-----------------------------------------------------------------
		
		if exists ( 
						select 1 
						from #TempTechnicalTrunkIDTable 
						where TechnicalTrunkID not in
						(
							Select TrunkID
							from ReferenceServer.UC_Reference.dbo.tb_Trunk
							where trunktypeID <> 9 -- Technical Trunks
							and flag & 1 <> 1
						)
					)
		Begin

			set @ErrorDescription = 'ERROR !!! List of TechnicalTrunk IDs passed contain value(s) which are not valid or do not exist'
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
				  GOTO PROCESSDESTINATIONGROUPLIST
				  
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

PROCESSDESTINATIONGROUPLIST:

		-----------------------------------------------------------------
		-- Create table for list of all selected Destinations groups from 
		-- the parameter passed
		-----------------------------------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDestinationGroupIDTable') )
				Drop table #TempDestinationGroupIDTable

		Create table  #TempDestinationGroupIDTable (DestinationGrpID varchar(100) )


		insert into #TempDestinationGroupIDTable
		select * from FN_ParseValueList ( @DestinationGroupIDList )

		----------------------------------------------------------------
		-- Check to ensure that none of the values are non numeric
		----------------------------------------------------------------

		if exists ( select 1 from #TempDestinationGroupIDTable where ISNUMERIC(DestinationGrpID) = 0 )
		Begin

			set @ErrorDescription = 'ERROR !!! List of Destination Group IDs passed contain a non numeric value'
			set @ResultFlag = 1
			Return 1

		End

		------------------------------------------------------
		-- Check if the All the Detinations have been selected 
		------------------------------------------------------

		if exists (
						select 1 
						from #TempDestinationGroupIDTable 
						where DEstinationGrpID = 0
				  )
		Begin

				  set @AllDestinationGroupFlag = 1
				  GOTO GENERATEREPORT
				  
		End

GENERATEREPORT:

      -----------------------------------------------------------------------------------------
	   -- Create table for Exchange rate, so that all data can be converted into base currency
	   -----------------------------------------------------------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempExchangeRate') )
				Drop table #tempExchangeRate

			Select ExchangeRate , CurrencyID , BeginDate , COnvert(datetime ,NULL) as EndDate
			into #tempExchangeRate 
			from REFERENCESERVER.UC_Reference.dbo.tb_Exchange
			order by CurrencyID , BeginDate

		Update tbl1 
		Set  EndDate = (
							Select Min(BeginDate) 
							From   #tempExchangeRate tbl2 
							Where  tbl1.CurrencyID = tbl2.CurrencyID 
							AND tbl1.BeginDate < tbl2.BeginDate
						) 
		FROM #tempExchangeRate tbl1

		---------------------------------------------------------------
		-- Insert record into the Temp Currency table for -1 currencyID
		-- to handle scenarios where currency is not resolved
		---------------------------------------------------------------

		insert into #tempExchangeRate values ( 1 , -1 , @StartDate , NULL)

		---------------------------------------------------------------------
		-- Select the subset of data on which report needs to be run based on
		-- Call Date
		---------------------------------------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempInUnionOutMonthlyFinancial') )
			Drop table #tempInUnionOutMonthlyFinancial

		select convert(int ,replace(convert(varchar(7) , CallDate , 120), '-' , '')) as CallMonth,
		DirectionID,
		sum(CallDuration) as CallDuration,
		sum(CircuitDuration) as CircuitDuration,
		sum(Answered) as Answered,
		sum(Seized) as Seized,
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
		sum(RoundedCallDuration) as RoundedCallDuration,
		sum(ChargeDuration) as ChargeDuration,
		sum(Amount/tbl2.ExchangeRate) as Amount,
		RateTypeID,
		tbl1.CurrencyID,
		ErrorIndicator
		into #tempInUnionOutMonthlyFinancial
		from tb_DailyINUnionOutFinancial tbl1
		inner join #tempExchangeRate tbl2 on tbl1.CallDate between tbl2.BeginDate and isnull(tbl2.EndDate , tbl1.CallDate)
											and tbl1.CurrencyID = tbl2.CurrencyID
		where convert(int ,replace(convert(varchar(7) , CallDate , 120), '-' , '')) between  @StartMonth and @EndMonth
		group by convert(int ,replace(convert(varchar(7) , CallDate , 120), '-' , '')),
		DirectionID,
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
		RateTypeID,
		tbl1.CurrencyID,
		ErrorIndicator

		select Case
					When substring(convert(varchar(6), CallMonth), 5,2) = 1 then 'Jan'
					When substring(convert(varchar(6), CallMonth), 5,2) = 2 then 'Feb'
					When substring(convert(varchar(6), CallMonth), 5,2) = 3 then 'Mar'
					When substring(convert(varchar(6), CallMonth), 5,2) = 4 then 'Apr'
					When substring(convert(varchar(6), CallMonth), 5,2) = 5 then 'May'
					When substring(convert(varchar(6), CallMonth), 5,2) = 6 then 'Jun'
					When substring(convert(varchar(6), CallMonth), 5,2) = 7 then 'Jul'
					When substring(convert(varchar(6), CallMonth), 5,2) = 8 then 'Aug'
					When substring(convert(varchar(6), CallMonth), 5,2) = 9 then 'Sep'
					When substring(convert(varchar(6), CallMonth), 5,2) = 10 then 'Oct'
					When substring(convert(varchar(6), CallMonth), 5,2) = 11 then 'Nov'
					When substring(convert(varchar(6), CallMonth), 5,2) = 12 then 'Dec'
			   End + ' ' +
			   substring(convert(varchar(6), CallMonth), 1,4) as CallMonth,
			   summ.DirectionID , dir.Direction,
			   summ.CallDuration , summ.CircuitDuration , summ.Answered, summ.Seized,
			   summ.CalltypeID , isnull(ct.CallType , '*****') as CallType,
			   summ.AccountID , isnull(acc.Account , '******') as Account,
			   summ.TrunkID , isnull(trnk.Trunk + '/' + Swt.Switch , '*****') as Trunk,
			   summ.CommercialTrunkID , isnull(ctrnk.Trunk , '*****') as CommercialTrunk,
			   summ.SettlementDestinationID , isnull(dest.Destination , '*****') as SettlementDestination,
			   summ.RoutingDestinationID , isnull(rdest.Destination , '*****') as RoutingDestination,
			   isnull(cou.CountryID, -1) as CountryID , isnull(cou.Country , '*****') as Country,
			   summ.INServiceLevelID , isnull(insl.ServiceLevel , '*****') as INServiceLevel,
			   summ.OutServiceLevelID , isnull(osl.ServiceLevel , '*****') as OUTServiceLevel,
			   summ.RatePlanID , isnull(rp.RatePlan , '******') as RatePlan,
			   summ.RatingMethodID , isnull(rm.RatingMethod , '*****') as RatingMethod,
			   summ.RoundedCallDuration , summ.ChargeDuration , summ.Amount , 
			   summ.RateTypeID , isnull(rti.RateItemName , '*****') as Ratetype,
			   summ.CurrencyID , isnull(curr.Currency , '*****') as Currency,
			   Case
					 When summ.ErrorIndicator = 1 then 'Error'
					 Else 'No Error'
			   End as ErrorIndicator,
			   isnull(DestGrp.EntityGroupID,summ.RoutingDestinationID)  as DestinationGroupID, isnull(DestGrp.EntityGroup ,isnull(rdest.Destination , '*****')) as DestinationGroup	
		into #TempDailyINUnionOutFinancial
		from #tempInUnionOutMonthlyFinancial summ
		left join REFERENCESERVER.UC_REference.dbo.tb_Direction dir on summ.DirectionID = dir.DirectionID
		left join REFERENCESERVER.UC_REference.dbo.tb_Calltype ct on summ.CalltypeID = ct.CallTypeID
		left join REFERENCESERVER.UC_REference.dbo.tb_Account acc on summ.AccountID = acc.AccountID
		left join REFERENCESERVER.UC_REference.dbo.tb_Trunk trnk on summ.TrunkID = trnk.TrunkID
		left join REFERENCESERVER.UC_REference.dbo.tb_Trunk ctrnk on summ.CommercialTrunkID = ctrnk.TrunkID
		left join REFERENCESERVER.UC_REference.dbo.tb_Destination dest on summ.SettlementDestinationID = dest.DestinationID
		left join REFERENCESERVER.UC_REference.dbo.tb_Destination rdest on summ.RoutingDestinationID = rdest.DestinationID
		left join REFERENCESERVER.UC_REference.dbo.tb_Country cou on rdest.CountryID = cou.CountryID
		left join REFERENCESERVER.UC_REference.dbo.tb_ServiceLevel insl on summ.INServiceLevelID = insl.ServiceLevelID
		left join REFERENCESERVER.UC_REference.dbo.tb_ServiceLevel osl on summ.OutServiceLevelID = osl.ServiceLevelID
		left join REFERENCESERVER.UC_REference.dbo.tb_RatePlan rp on summ.RatePlanID = rp.RatePlanID
		left join REFERENCESERVER.UC_REference.dbo.tb_RatingMethod rm on summ.RatingMethodID = rm.RatingmethodID
		left join REFERENCESERVER.UC_REference.dbo.tb_RateItem rti on summ.RatetypeID = rti.RateItemID
		left join REFERENCESERVER.UC_REference.dbo.tb_Currency curr on summ.CurrencyID = curr.CurrencyID
		left join ReferenceServer.UC_Reference.dbo.tb_Switch Swt on Trnk.SwitchID = Swt.SwitchID
		left join
		(
			select tbl1.EntityGroupID , tbl1.EntityGroup, tbl2.InstanceID
			from Referenceserver.UC_Reference.dbo.tb_EntityGroup tbl1
			inner join Referenceserver.UC_Reference.dbo.tb_EntityGroupMember tbl2 on tbl1.EntityGroupID = tbl2.EntityGroupID
			inner join Referenceserver.UC_Reference.dbo.tb_Destination tbl3 on tbl2.InstanceID = tbl3.DestinationID
			where EntityGroupTypeID = -2
			and tbl3.NumberPlanID = -1 -- Only Routing number plan grouping
			and tbl1.Flag & 1 <> 1
		) DestGrp on summ.RoutingDestinationID = DestGrp.InstanceID
		and summ.CalltypeID  = isnull(@CalltypeID , summ.CallTypeID)
		
        ------------------------------------------------------------------------
		-- Create a temporary table to store all the result sets of the query
		------------------------------------------------------------------------ 

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempQueryResultSet') )
				Drop table #tempQueryResultSet

        Create table #tempQueryResultSet
		(
			Param1 varchar(100),
			Param1Value varchar(100),
			Param2 varchar(100),
			Param2Value varchar(100),
			Param3 varchar(100),
			Param3Value varchar(100),
			Param4 varchar(100),
			Param4Value varchar(100),
			DirectionID int,
			Answered int,
			Seized int,
			OriginalMinutes Decimal(19,2),
			ChargeMinutes Decimal(19,2),
			Amount Decimal(19,2),
			Rate Decimal(19,6)
		)

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempQueryResultSetSummarize') )
				Drop table #tempQueryResultSetSummarize

        Create table #tempQueryResultSetSummarize
		(
			Param1 varchar(100),
			Param1Value varchar(100),
			Param2 varchar(100),
			Param2Value varchar(100),
			Param3 varchar(100),
			Param3Value varchar(100),
			Param4 varchar(100),
			Param4Value varchar(100),
			Answered int,
			Seized int,
			ASR int,
			ActualINMinutes Decimal(19,2),
			INChargeMinutes Decimal(19,2),
			Revenue Decimal(19,2),
			RPM Decimal(19,6),
			ActualOUTMinutes Decimal(19,2),
			OUTChargeMinutes Decimal(19,2),
			Cost Decimal(19,2),
			CPM Decimal(19,6)
		)

		-----------------------------------------------------
		-- Extract the result set for the input parameters
		-----------------------------------------------------
	
		set @SQLStr1 = 'Select ' + isnull(@Level1ParamFormat, '''None''') + ', ' + isnull(convert(varchar(100) ,'tbl1.' +@Level1ParamValue) , '''None''')+ ', ' + Char(10) +
		        isnull(@Level2ParamFormat, '''None''') + ', ' + isnull(convert(varchar(100) ,@Level2ParamValue), '''None''') + ', ' + Char(10) +
				isnull(@Level3ParamFormat, '''None''') + ', ' + isnull(convert(varchar(100) ,@Level3ParamValue), '''None''') + ', ' + Char(10) +
				isnull(@Level4ParamFormat, '''None''')+ ', ' + isnull(convert(varchar(100) ,@Level4ParamValue), '''None''') + ', ' + Char(10) +
		        'DirectionID, ' + char(10) +
		        'sum(tbl1.Answered) , sum(tbl1.Seized) , ' + char(10) +
				'convert(Decimal(19,2),sum(CallDuration/60.0)) ,' +  char(10) +
				'convert(Decimal(19,2),sum(ChargeDuration)) ,' +  char(10) +
				'convert(Decimal(19,2) ,Sum(Amount)), ' + char(10) +
				'case ' + char(10)+
				'    when Sum(ChargeDuration) = 0 then 0.0000 ' + char(10) +
				'    else convert(decimal(19,6) ,sum(Amount)/ Sum(ChargeDuration)) ' + char(10) +
			    'end ' + char(10)



        set @SQLStr2 = ' from #TempDailyINUnionOutFinancial tbl1 ' + char(10) +
		                Case
						    When @AllAccountFlag = 1 then ''
							Else ' inner join #TempAccountIDTable tbl2 on tbl1.AccountID = tbl2.AccountID ' + char(10)
						End + 
		                Case
						    When  @AllServiceLevelFlag = 1 then ''
							Else ' inner join #TempServiceLevelIDTable tbl3 on tbl1.INServiceLevelID = tbl3.ServiceLevelID ' + char(10)
						End +
		                Case
						    When  @AllDestinationFlag  = 1 then ''
							Else ' inner join #TempDestinationIDTable tbl4 on tbl1.RoutingDestinationID = tbl4.DestinationID ' + char(10)
						End +
		                Case
						    When  @AllCountryFlag = 1 then ''
							Else ' inner join #TempCountryIDTable tbl5 on tbl1.CountryID = tbl5.CountryID ' + char(10)
						End +
		                Case
						    When  @AllCommercialTrunkFlag  = 1 then ''
							Else ' inner join #TempCommercialTrunkIDTable tbl6 on tbl1.CommercialTrunkID = tbl6.CommercialTrunkID ' + char(10)
						End +
		                Case
						    When  @AllTechnicalTrunkFlag   = 1 then ''
							Else ' inner join #TempTechnicalTrunkIDTable tbl7 on tbl1.TrunkID = tbl7.TechnicalTrunkID ' + char(10)
						End +
		                Case
						    When  @AllDestinationGroupFlag   = 1 then ''
							Else ' inner join #TempDestinationGroupIDTable tbl9 on tbl1.DestinationGroupID = tbl9.DestinationGrpID ' + char(10)
						End +
						'inner join #tempExchangeRate tbl8 on tbl1.CurrencyID = tbl8.CurrencyID' + char(10)


		set @SQLStr3 = 'Where 1 = 1 ' +  char(10) +
					   'Group by DirectionID ' +
					   Case
					   		When @Level1Param is NULL then ''
							Else ' , ' + @Level1Param + ' , tbl1.' + @Level1ParamValue
					   End + 
					   Case
					   		When @Level2Param is NULL then ''
							Else ' , ' + @Level2Param + ' , tbl1.' + @Level2ParamValue
					   End +	
					   Case
					   		When @Level3Param is NULL then ''
							Else ' , ' + @Level3Param + ' , tbl1.' + @Level3ParamValue
					   End +
					   Case
					   		When @Level4Param is NULL then ''
							Else ' , ' + @Level4Param + ' , tbl1.' + @Level4ParamValue
					   End 				   					   				   
                      


        set @SQLStr = @SQLStr1 + @SQLStr2 + @SQLStr3

		--print @SQLStr

		insert into #tempQueryResultSet
		Exec (@SQLStr)

		---------------------------------------------------------------------------
		-- Summarize and add the Resultset into the final summary table for display
		---------------------------------------------------------------------------

		insert into #tempQueryResultSetSummarize (Param1, Param2 , Param3, Param4, Param1Value, Param2Value, Param3Value, Param4Value )
		select distinct Param1, Param2 , Param3 , Param4, Param1Value , Param2Value , Param3Value, Param4Value
		from #tempQueryResultSet

		update #tempQueryResultSetSummarize
		set Answered = 0,
		    Seized = 0,
			ASR = 0,
			ActualINMinutes = 0,
			INChargeMinutes = 0,
			Revenue = 0,
			RPM = 0,
			ActualOUTMinutes = 0 ,
			OUTChargeMinutes = 0,
			Cost  = 0,
			CPM = 0

        update tbl1
		set Answered = tbl1.Answered + tbl2.Answered,
		    Seized = tbl1.Seized + tbl2.Seized,
			ActualINMinutes = tbl2.OriginalMinutes,
			INChargeMinutes = tbl2.ChargeMinutes,
			Revenue = tbl2.Amount,
			RPM = tbl2.Rate
		from #tempQueryResultSetSummarize tbl1
		inner join #tempQueryResultSet tbl2 on tbl1.Param1Value = tbl2.Param1Value 
		                                  and tbl1.Param2Value = tbl2.Param2Value
		                                  and tbl1.Param3Value = tbl2.Param3Value
		                                  and tbl1.Param4Value = tbl2.Param4Value
		where tbl2.DirectionID = 1

        update tbl1
		set Answered = tbl1.Answered + tbl2.Answered,
		    Seized = tbl1.Seized + tbl2.Seized,
			ActualOUTMinutes = tbl2.OriginalMinutes,
			OUTChargeMinutes = tbl2.ChargeMinutes,
			Cost = tbl2.Amount,
			CPM = tbl2.Rate
		from #tempQueryResultSetSummarize tbl1
		inner join #tempQueryResultSet tbl2 on tbl1.Param1Value = tbl2.Param1Value
		                                  and tbl1.Param2Value = tbl2.Param2Value
		                                  and tbl1.Param3Value = tbl2.Param3Value
		                                  and tbl1.Param4Value = tbl2.Param4Value
		where tbl2.DirectionID = 2

		update #tempQueryResultSetSummarize
		set ASR = convert(int , (Answered * 100.0)/Seized)

		select  Param1 ,
				Param2 ,
				Param3 ,
				Param4 ,
				Answered ,
				Seized ,
				ASR,
				ActualINMinutes,
				INChargeMinutes,
				Revenue ,
				RPM,
				ActualOUTMinutes,
				OUTChargeMinutes ,
				Cost,
				CPM 
		from #tempQueryResultSetSummarize


		-------------------------------------------------------------------
		-- Calculate TOTAL for the the above query set to display in report
		--------------------------------------------------------------------

		select @TotalResult =
		  	   'TOTAL' + '|' +
				'' + '|' + '' + '|' + '' + '|' +
				convert(varchar(100) ,sum(convert(decimal(19,0),Answered))) + '|' +
				convert(varchar(100) ,sum(convert(decimal(19,0),Seized))) + '|' +
				convert(varchar(100) ,convert(int , (sum(convert(decimal(19,2) ,Answered))* 100.0)/sum(Convert(Decimal(19,2) ,Seized)))) + '|' +
				convert(varchar(100) ,sum(ActualINMinutes)) + '|' + 
				convert(varchar(100) ,sum(INChargeMinutes)) + '|' +
				convert(varchar(100) ,sum(Revenue)) + '|' +
				convert(varchar(100),
				Case
						When sum(INChargeMinutes) = 0 then 0
						Else convert(decimal(19,6) ,sum(Revenue)/sum(INChargeMinutes))
				End )  + '|' +
				convert(varchar(100),sum(ActualOUTMinutes)) + '|' +
				convert(varchar(100),sum(OUTChargeMinutes)) + '|' +
				convert(varchar(100),sum(Cost)) + '|' +
				convert(varchar(100),
				Case
						When sum(OUTChargeMinutes) = 0 then 0
						Else convert(decimal(19,6) ,sum(Cost)/sum(OUTChargeMinutes))
				End )
		from #tempQueryResultSetSummarize

		if ( @TotalResult is NULL )
		Begin

				select @TotalResult =
		  	   'TOTAL' + '|' +
				'' + '|' + '' + '|' + '' + '|' +
				'0.00' + '|' + 	'0.00' + '|' +
				'0.00' + '|' +	'0.00' + '|' + 
				'0.00' + '|' +	'0.00' + '|' +
				'0.00' + '|' +	'0.00' + '|' +
				'0.00' + '|' +	'0.00' + '|' +
				'0.00'

		End

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!! While extracting Cost Revenue ASR Report. '+ ERROR_MESSAGE()
		set @ResultFlag = 1
		GOTO ENDPROCESS

End Catch

--Select 'Step 4..' , getdate()

ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempExchangeRate') )
		Drop table #tempExchangeRate

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAccountIDTable') )
		Drop table #TempAccountIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempTechnicalTrunkIDTable') )
		Drop table #TempTechnicalTrunkIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCommercialTrunkIDTable') )
		Drop table #TempCommercialTrunkIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCountryIDTable') )
		Drop table #TempCountryIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempServiceLevelIDTable') )
		Drop table #TempServiceLevelIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDestinationIDTable') )
		Drop table #TempDestinationIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempQueryResultSet') )
		Drop table #tempQueryResultSet

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempQueryResultSetSummarize') )
		Drop table #tempQueryResultSetSummarize

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDailyINUnionOutFinancial') )
		Drop table #TempDailyINUnionOutFinancial

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDestinationGroupIDTable') )
		Drop table #TempDestinationGroupIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempInUnionOutMonthlyFinancial') )
		Drop table #tempInUnionOutMonthlyFinancial



GO
