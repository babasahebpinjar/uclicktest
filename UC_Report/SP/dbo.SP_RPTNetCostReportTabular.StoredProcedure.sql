USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_RPTNetCostReportTabular]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_RPTNetCostReportTabular]
(
     @ReportID int,
	 @StartDate datetime,
	 @EndDate datetime,  
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
		@SQLStr  nvarchar(max)

---------------------------------------------------------
-- Check if the Report is valid and exists in he system
---------------------------------------------------------

if not exists ( select 1 from tb_Report where ReportID = @ReportID and Flag & 1 <> 1 )
Begin

		set @ErrorDescription = 'ERROR !!! Report ID is not valid or is not active (flag <> 0)'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End

-------------------------------------------------------------------
-- Check if the different Level parameters are valid and are part
-- of the summarization parameters for this report 
-------------------------------------------------------------------

Declare @Level1ParamID int,
        @Level2ParamID int,
		@Level3ParamID int,
		@Level4ParamID int

Declare @Level1ParamFormat varchar(100),
        @Level2ParamFormat varchar(100),
		@Level3ParamFormat varchar(100),
		@Level4ParamFormat varchar(100)

if ( (@Level1Param is NOT NULL) )
Begin

	select @Level1ParamID = RptSummarizeParameterID,
	       @Level1ParamFormat = RptSummarizeParameterFormat
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
	       @Level2ParamFormat = RptSummarizeParameterFormat
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
	       @Level3ParamFormat = RptSummarizeParameterFormat
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
	       @Level4ParamFormat = RptSummarizeParameterFormat
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
			set @ErrorDescription = 'ERROR !!! Level 4 parameter : ' + @Level4Param + ' is not valid for this report'
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

		Create table  #TempDestinationGroupIDTable (DestinationGroupID varchar(100) )


		insert into #TempDestinationGroupIDTable
		select * from FN_ParseValueList ( @DestinationGroupIDList )

		----------------------------------------------------------------
		-- Check to ensure that none of the values are non numeric
		----------------------------------------------------------------

		if exists ( select 1 from #TempDestinationGroupIDTable where ISNUMERIC(DestinationGroupID) = 0 )
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
						where DEstinationGroupID = 0
				  )
		Begin

				  set @AllDestinationGroupFlag = 1
				  GOTO GENERATEREPORT
				  
		End
		
        --------------------------------------------------------------------------
		-- Check to ensure that all the Destination Groups passed are valid values
		--------------------------------------------------------------------------
		
		if exists ( 
						select 1 
						from #TempDestinationGroupIDTable 
						where DestinationGroupID not in
						(
							select distinct tbl1.EntityGroupID
							from Referenceserver.UC_Reference.dbo.tb_EntityGroup tbl1
							inner join Referenceserver.UC_Reference.dbo.tb_EntityGroupMember tbl2 on tbl1.EntityGroupID = tbl2.EntityGroupID
							inner join Referenceserver.UC_Reference.dbo.tb_Destination tbl3 on tbl2.InstanceID = tbl3.DestinationID
							where EntityGroupTypeID = -2
							and tbl3.NumberPlanID = -1 -- Only Routing number plan grouping
							and tbl1.Flag & 1 <> 1
						)
					)
		Begin

			set @ErrorDescription = 'ERROR !!! List of Destination Group IDs passed contain value(s) which are not valid or do not exist'
			set @ResultFlag = 1
			Return 1

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

		select summ.CallDate ,
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
			   summ.Rate,
			   summ.RateTypeID , isnull(rti.RateItemName , '*****') as Ratetype,
			   summ.CurrencyID , isnull(curr.Currency , '*****') as Currency,
			   Case
					 When summ.ErrorIndicator = 1 then 'Error'
					 Else 'No Error'
			   End as ErrorIndicator,
			   isnull(DestGrp.EntityGroupID,summ.RoutingDestinationID)  as DestinationGroupID, isnull(DestGrp.EntityGroup ,isnull(rdest.Destination , '*****')) as DestinationGroup		
		into #TempDailyINUnionOutFinancial
		from tb_DailyINUnionOutFinancial summ
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
		where CallDate between @StartDate and @EndDate
		and summ.CallTypeID = isnull(@CallTypeID , summ.CalltypeID)


		-----------------------------------------------------
		-- Extract the result set for the input parameters
		-----------------------------------------------------

		if ( (@Level1Param is NULL) and (@Level2Param is NULL) and (@Level3Param is NULL) and (@Level4Param is NULL) )
		Begin


				set @SQLStr1 = 'Select ''' + 'None' + ''' as Param1, ''' + 'None' + ''' as Param2, ''' + Char(10) +
							   'None' + ''' as Param3, ''' + 'None' + ''' as Param4, ' + Char(10) +
							  'tbl1.Answered,tbl1.Seized , ' + char(10) +
							  'convert(int ,((tbl1.Answered * 1.00)/tbl1.Seized) * 100) as ASR , ' + char(10) +
							  'convert(Decimal(19,2),(CallDuration/60.0)) as OriginalMinutes ,' +  char(10) +
							  'convert(Decimal(19,2),ChargeDuration) as ChargeMinutes ,' +  char(10) +
							  'convert(Decimal(19,2) ,(Amount/tbl8.ExchangeRate)) as Cost, ' + char(10) +
							  'case ' + char(10)+
							  '    when ChargeDuration = 0 then 0.0000 ' + char(10) +
							  '    else convert(decimal(19,6) ,(Amount/tbl8.ExchangeRate)/ChargeDuration) ' + char(10) +
							  'end as CPM' + char(10)
		End

		Else
		Begin

				set @SQLStr1 = 'Select ' + isnull(@Level1ParamFormat, '''None''') + ' as Param1, ' + isnull(@Level2ParamFormat, '''None''') + ' as Param2, ' + Char(10) +
							   isnull(@Level3ParamFormat, '''None''') + ' as Param3, ' + isnull(@Level4ParamFormat,'''None''') + ' as Param4, ' + Char(10) +
							  'sum(tbl1.Answered) as Answered , sum(tbl1.Seized) as Seized , ' + char(10) +
							  'convert(int ,(sum(tbl1.Answered * 1.00)/sum(tbl1.Seized)) * 100) as ASR , ' + char(10) +
							  'convert(Decimal(19,2),sum(CallDuration/60.0)) as OriginalMinutes ,' +  char(10) +
							  'convert(Decimal(19,2),sum(ChargeDuration)) as ChargeMinutes ,' +  char(10) +
							  'convert(Decimal(19,2) ,Sum(Amount/tbl8.ExchangeRate)) as Cost, ' + char(10) +
							  'case ' + char(10)+
							  '    when Sum(ChargeDuration) = 0 then 0.0000 ' + char(10) +
							  '    else convert(decimal(19,6) ,sum(Amount/tbl8.ExchangeRate)/ Sum(ChargeDuration)) ' + char(10) +
							  'end as CPM' + char(10)


		End


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
							Else ' inner join #TempDestinationGroupIDTable tbl9 on tbl1.DestinationGroupID = tbl9.DestinationGroupID ' + char(10)
						End +	
						'inner join #tempExchangeRate tbl8 on tbl1.CurrencyID = tbl8.CurrencyID' + char(10)

		if ( (@Level1Param is NULL) and (@Level2Param is NULL) and (@Level3Param is NULL) and (@Level4Param is NULL) )
		Begin

				set @SQLStr3 = 'Where tbl1.Directionid = 2 ' +  char(10) +
					   'and tbl1.CallDate between tbl8.BeginDate and isnull(tbl8.EndDate , tbl1.CallDate) '

		End

		Else
		Begin

				set @SQLStr3 = 'Where tbl1.Directionid = 2 ' +  char(10) +
							   'and tbl1.CallDate between tbl8.BeginDate and isnull(tbl8.EndDate , tbl1.CallDate) ' +  char(10) +
							   'Group by ' + 
							   Case

									When @Level1Param is NULL then ''
									Else @Level1Param + ','

							   End +
							   Case

									 When @Level2Param is NULL then ''
									 Else @Level2Param + ','

							   End +
							   Case

									When @Level3Param is NULL then ''
									Else @Level3Param + ','

							   End +
							   Case

									 When @Level4Param is NULL then ''
									 Else @Level4Param 

							   End 

                   if ( right( @SQLStr3, 1) = ',')
				        set  @SQLStr3 = substring(@SQLStr3 , 1 , len(@SQLStr3) - 1)

		End


        set @SQLStr = @SQLStr1 + @SQLStr2 + @SQLStr3

		--print @SQLStr

		Exec (@SQLStr)

		-------------------------------------------------------------------
		-- Extract the TOTAL for the result set to be displayed in Report
		-------------------------------------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempTotalResult') )
				Drop table #tempTotalResult

       Create table #tempTotalResult
	   (
			Param1 varchar(100),
			Param2 varchar(100),
			Param3 varchar(100),
			Param4 varchar(100),
			Answered int,
			Seized int,
			ASR int,
			OriginalMinutes Decimal(19,2),
            ChargeMinutes Decimal(19,2),
			Cost Decimal(19,2),
			CPM Decimal(19,6)
	   )

		set @SQLStr1 = 'Select ''TOTAL'', '''', ' + Char(10) +
					''''', '''', ' + Char(10) +
					'isnull(sum(tbl1.Answered),0) , isnull(sum(tbl1.Seized),0) , ' + char(10) +
					'isnull(convert(int ,(sum(tbl1.Answered * 1.00)/sum(tbl1.Seized)) * 100),0) , ' + char(10) +
					'isnull(convert(Decimal(19,2),sum(CallDuration/60.0)),0) ,' +  char(10) +
					'isnull(convert(Decimal(19,2),sum(ChargeDuration)),0) ,' +  char(10) +
					'isnull(convert(Decimal(19,2) ,Sum(Amount/tbl8.ExchangeRate)),0), ' + char(10) +
					'case ' + char(10)+
					'    when isnull(Sum(ChargeDuration), 0) = 0 then 0.0000 ' + char(10) +
					'    else isnull(convert(decimal(19,6) ,sum(Amount/tbl8.ExchangeRate)/ Sum(ChargeDuration)),0) ' + char(10) +
					'end' + char(10)	

		set @SQLStr3 = 'Where tbl1.Directionid = 2 ' +  char(10) +
					   'and tbl1.CallDate between tbl8.BeginDate and isnull(tbl8.EndDate , tbl1.CallDate) '

        set @SQLStr = @SQLStr1 + @SQLStr2 + @SQLStr3

		--print @SQLStr

		insert into #tempTotalResult
		Exec (@SQLStr)


		select 	@TotalResult = 
				Param1 + '|' + Param2 + '|' + Param3 + '|' + Param4 + '|' +
				convert(varchar(100), isnull(Answered, 0)) + '|'+
				convert(varchar(100) ,isnull(Seized,0)) + '|' +
				convert(varchar(100) ,isnull(ASR,0)) + '|' +
				convert(varchar(100) ,isnull(OriginalMinutes,0)) + '|' +
				convert(varchar(100), isnull(ChargeMinutes,0)) + '|' +
				convert(varchar(100) ,isnull(Cost,0)) + '|' +
				convert(varchar(100) ,isnull(CPM,0))
		from #tempTotalResult


End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!! While extracting Net Cost Report. '+ ERROR_MESSAGE()
		set @ResultFlag = 1
		GOTO ENDPROCESS

End Catch

--Select 'Step 4..' , getdate()

ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempExchangeRate') )
		Drop table #tempExchangeRate

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempTotalResult') )
		Drop table #tempTotalResult


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

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDailyINUnionOutFinancial') )
		Drop table #TempDailyINUnionOutFinancial

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDestinationGroupIDTable') )
		Drop table #TempDestinationGroupIDTable
GO
