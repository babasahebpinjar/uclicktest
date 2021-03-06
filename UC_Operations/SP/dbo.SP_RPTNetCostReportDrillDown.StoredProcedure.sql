USE [UC_Operations]
GO
/****** Object:  StoredProcedure [dbo].[SP_RPTNetCostReportDrillDown]    Script Date: 5/2/2020 6:25:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_RPTNetCostReportDrillDown]
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
	 @SummarizeBy varchar(100),
	 @Level1Param varchar(100),
	 @Level1ParamValue varchar(100),
	 @Level2Param varchar(100),
	 @Level2ParamValue varchar(100),
	 @Level3Param varchar(100),
	 @Level3ParamValue varchar(100),
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
-- Check to see if the Summarize By Parameter is valid for this
-- report or not and extract the Parameter Name and Value
-------------------------------------------------------------------

Declare @SummarizeParamName varchar(100) = @SummarizeBy,
        @SummarizeParamValue varchar(100),
		@SummarizeParameterID int,
		@SummarizeParameterFormat varchar(100)

if  ( @SummarizeParamName is not NULL)
Begin

		select @SummarizeParamValue = RptSummarizeParameterValue,
			   @SummarizeParameterID = RptSummarizeParameterID,
			   @SummarizeParameterFormat = RptSummarizeParameterFormat
		from tb_RptSummarizeParameter
		where RptSummarizeParameterName = @SummarizeBy
		and flag & 1 <> 1

		if ( @SummarizeParameterID is NULL )
		Begin
				set @ErrorDescription = 'ERROR !!! Summarization parameter : ' + @SummarizeBy + ' is not valid'
				set @ResultFlag = 1
				GOTO ENDPROCESS
		End

		if not exists ( select 1 from tb_ReportParam where ReportID = @ReportID and ParameterID = @SummarizeParameterID and flag & 1 <> 1 )
		Begin
				set @ErrorDescription = 'ERROR !!! Summarization parameter : ' + @SummarizeBy + ' is not valid for this report'
				set @ResultFlag = 1
				GOTO ENDPROCESS

		End 

End


-------------------------------------------------------------------
-- Check if the different Level parameters are valid and are part
-- of the summarization parameters for this report 
-------------------------------------------------------------------

Declare @Level1ParamID int,
        @Level2ParamID int,
		@Level3ParamID int

if ( (@Level1Param is NOT NULL) )
Begin

	select @Level1ParamID = RptSummarizeParameterID
	from tb_RptSummarizeParameter
	where RptSummarizeParameterValue = @Level1Param
	and flag & 1 <> 1

	if not exists ( select 1 from tb_ReportParam where ReportID = @ReportID and ParameterID = @Level1ParamID and flag & 1 <> 1 )
	Begin
			set @ErrorDescription = 'ERROR !!! Level 1 parameter : ' + @Level1Param + ' is not valid for this report'
			set @ResultFlag = 1
			GOTO ENDPROCESS

	End

End

if ( (@Level2Param is NOT NULL) )
Begin

	select @Level2ParamID = RptSummarizeParameterID
	from tb_RptSummarizeParameter
	where RptSummarizeParameterValue = @Level2Param
	and flag & 1 <> 1

	if not exists ( select 1 from tb_ReportParam where ReportID = @ReportID and ParameterID = @Level2ParamID and flag & 1 <> 1 )
	Begin
			set @ErrorDescription = 'ERROR !!! Level 2 parameter : ' + @Level2Param + ' is not valid for this report'
			set @ResultFlag = 1
			GOTO ENDPROCESS

	End

End

if ( (@Level3Param is NOT NULL) )
Begin

	select @Level3ParamID = RptSummarizeParameterID
	from tb_RptSummarizeParameter
	where RptSummarizeParameterValue = @Level3Param
	and flag & 1 <> 1

	if not exists ( select 1 from tb_ReportParam where ReportID = @ReportID and ParameterID = @Level3ParamID and flag & 1 <> 1 )
	Begin
			set @ErrorDescription = 'ERROR !!! Level 3 parameter : ' + @Level3Param + ' is not valid for this report'
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
				  GOTO GENERATEREPORT
				  
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
			   End as ErrorIndicator
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
		where CallDate between @StartDate and @EndDate
		and summ.CallTypeID = isnull(@CallTypeID , summ.CalltypeID)


		-----------------------------------------------------
		-- Extract the result set for the input parameters
		-----------------------------------------------------

		if ( @SummarizeParamName is not NULL )
		Begin

				set @SQLStr1 = 'Select ' + @SummarizeParameterFormat + ' as ParamName, ' + convert(varchar(100),@SummarizeParamValue) + ' as ParamValue, ' + Char(10) +
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

		 Else
		 Begin

				set @SQLStr1 = 'Select ''None'' as ParamName , ''None'' as ParamValue ,' + Char(10) +
							  'tbl1.Answered as Answered , tbl1.Seized as Seized , ' + char(10) +
							  'convert(int ,((tbl1.Answered * 1.00)/tbl1.Seized) * 100) as ASR , ' + char(10) +
							  'convert(Decimal(19,2),(CallDuration/60.0)) as OriginalMinutes ,' +  char(10) +
							  'convert(Decimal(19,2),ChargeDuration) as ChargeMinutes ,' +  char(10) +
							  'convert(Decimal(19,2) ,(Amount/tbl8.ExchangeRate)) as Cost, ' + char(10) +
							  'case ' + char(10)+
							  '    when ChargeDuration = 0 then 0.0000 ' + char(10) +
							  '    else convert(decimal(19,6) ,(Amount/tbl8.ExchangeRate)/ChargeDuration) ' + char(10) +
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
						'inner join #tempExchangeRate tbl8 on tbl1.CurrencyID = tbl8.CurrencyID' + char(10)

        if ( (@Level1Param is NULL)  and (@Level2Param is NULL)  and (@Level3Param is NULL) )
		Begin

				   if ( @SummarizeParamName is NULL )
				   Begin

							set @SQLStr3 = 'Where tbl1.Directionid = 2 ' +  char(10) +
										   'and tbl1.CallDate between tbl8.BeginDate and isnull(tbl8.EndDate , tbl1.CallDate) '

				   End
				   Else
				   Begin

						set @SQLStr3 = 'Where tbl1.Directionid = 2 ' +  char(10) +
									   'and tbl1.CallDate between tbl8.BeginDate and isnull(tbl8.EndDate , tbl1.CallDate) ' +  char(10) +
									   'Group by ' + @SummarizeParamName + ' , ' + @SummarizeParamValue + char(10) +
									   'Order By ' + @SummarizeParamName


					End

		End

		Else
		Begin

					set @SQLStr3 = 'Where tbl1.Directionid = 1 ' +  char(10) +
								   'and tbl1.CallDate between tbl8.BeginDate and isnull(tbl8.EndDate , tbl1.CallDate) ' +  char(10) +
								   Case
										When @Level1Param is NULL then ''
										Else 'and tbl1.' + @Level1Param + '= ''' + @Level1ParamValue + '''' + char(10)
								   End +
								   Case
										When @Level2Param is NULL then ''
										Else 'and tbl1.' + @Level2Param + '= ''' + @Level2ParamValue + '''' + char(10)
								   End +
								   Case
										When @Level3Param is NULL then ''
										Else 'and tbl1.' + @Level3Param + '= ''' + @Level3ParamValue + '''' + char(10)
								   End +
								   Case
										When @SummarizeParamName is NULL then ''
										Else 'Group by ' + @SummarizeParamName + ' , ' + @SummarizeParamValue + Char(10)+
											'Order By ' + @SummarizeParamName
							       End

        End

		set @SQLStr = @SQLStr1 + @SQLStr2 + @SQLStr3

		--print @SQLStr

		Exec (@SQLStr)

		----------------------------------------------------------------------
		-- Extract the TOTAL for the Result Set to be displayed in the report
		----------------------------------------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempTotalResult') )
				Drop table #tempTotalResult

        Create table #tempTotalResult
		(
			ParamName varchar(100),
			ParamValue varchar(100),
			Answered int,
			Seized int,
			ASR int,
			OriginalMinutes Decimal(19,2),
			ChargeMinutes Decimal(19,2),
			Cost Decimal(19,2),
			CPM Decimal(19,6)
		)

		set @SQLStr1 = 'Select ''TOTAL'', '''' , ' + Char(10) +
						'sum(tbl1.Answered) , sum(tbl1.Seized), ' + char(10) +
						'convert(int ,(sum(tbl1.Answered * 1.00)/sum(tbl1.Seized)) * 100) , ' + char(10) +
						'convert(Decimal(19,2),sum(CallDuration/60.0)) ,' +  char(10) +
						'convert(Decimal(19,2),sum(ChargeDuration)),' +  char(10) +
						'convert(Decimal(19,2) ,Sum(Amount/tbl8.ExchangeRate)), ' + char(10) +
						'case ' + char(10)+
						'    when Sum(ChargeDuration) = 0 then 0.0000 ' + char(10) +
						'    else convert(decimal(19,6) ,sum(Amount/tbl8.ExchangeRate)/ Sum(ChargeDuration)) ' + char(10) +
						'end' + char(10)

		set @SQLStr3 = 'Where tbl1.Directionid = 2 ' +  char(10) +
						'and tbl1.CallDate between tbl8.BeginDate and isnull(tbl8.EndDate , tbl1.CallDate) ' +  char(10) +
						Case
							When @Level1Param is NULL then ''
							Else 'and tbl1.' + @Level1Param + '= ''' + @Level1ParamValue + '''' + char(10)
						End +
						Case
							When @Level2Param is NULL then ''
							Else 'and tbl1.' + @Level2Param + '= ''' + @Level2ParamValue + '''' + char(10)
						End +
						Case
							When @Level3Param is NULL then ''
							Else 'and tbl1.' + @Level3Param + '= ''' + @Level3ParamValue + '''' + char(10)
						End

        set @SQLStr = @SQLStr1 + @SQLStr2 + @SQLStr3

		--print @SQLStr

		insert into #tempTotalResult
		Exec (@SQLStr)

		Select @TotalResult = 
		      ParamName + '|' + ParamValue + '|' +
			  convert(varchar(100) , Answered) + '|' +
			  convert(varchar(100) ,Seized) + '|' +
			  convert(varchar(100) ,ASR) + '|' +
			  convert(varchar(100) ,OriginalMinutes) + '|' +
			  convert(varchar(100) ,ChargeMinutes) + '|' +
			  convert(varchar(100) ,Cost) + '|' +
			  convert(varchar(100) ,CPM )
		from #tempTotalResult

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!! While extracting Net Cost Report. '+ ERROR_MESSAGE()
		set @ResultFlag = 1
		GOTO ENDPROCESS

End Catch

--Select 'Step 4..' , getdate()

ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempTotalResult') )
		Drop table #tempTotalResult

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

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDailyINUnionOutFinancial') )
		Drop table #TempDailyINUnionOutFinancial
GO
