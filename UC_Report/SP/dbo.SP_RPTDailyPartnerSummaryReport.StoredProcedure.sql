USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_RPTDailyPartnerSummaryReport]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_RPTDailyPartnerSummaryReport]
(
     @ReportID int,
	 @StartDate datetime,
	 @EndDate datetime,  
	 @CallTypeID int,
	 @AccountID int, 
 	 @ServiceLevelIDList nvarchar(max),
	 @DirectionID int,
	 @TotalErrorResult nvarchar(max) Output,
	 @TotalNoErrorResult nvarchar(max) Output,
 	 @ErrorDescription varchar(2000) Output,
	 @ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @SQLStr1 nvarchar(max),
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

-------------------------------------------------------------
-- Set the CALL TYPE to NULL in case the value passed is 0
-- indicating that all CALL TYPES need to be considered
-------------------------------------------------------------

if ( @CallTypeID = 0 )
	set @CallTypeID = NULL

--------------------------------------------------------------------
-- Check to ensure that the ACCOUNT ID is a valid value and exists
-- in the system
--------------------------------------------------------------------

if not exists ( select 1 from ReferenceServer.UC_Reference.dbo.tb_Account where AccountID = isnull(@AccountID , -9999) and flag & 1 <> 1 )
Begin

		set @ErrorDescription = 'ERROR !!! Account ID is either NULL or not a valid value'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End



--------------------------------------------------------------------
-- Check to ensure that the DIRECTION ID is a valid value and exists
-- in the system
--------------------------------------------------------------------

if ( isnull(@DirectionID, -9999) not in (1,2) )
Begin

		set @ErrorDescription = 'ERROR !!! Direction ID is either NULL or not a valid value. Correct values are  ( 1 - Inbound , 2 - Outbound)'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End

Begin Try


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

				  delete from #TempServiceLevelIDTable

				  insert into #TempServiceLevelIDTable
				  Select ServiceLevelID
				  from ReferenceServer.UC_Reference.dbo.tb_ServiceLevel
				  where DirectionID = 1 -- All INBOUND Service Levels
							and flag & 1 <> 1

				  GOTO GENERATEREPORT
				  
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

GENERATEREPORT:

		---------------------------------------------------------------------
		-- Select the subset of data on which report needs to be run based on
		-- Call Date
		---------------------------------------------------------------------

		select summ.CallDate ,
		       summ.CalltypeID , cp.CallType,
			   summ.CallDuration , summ.Answered, summ.Seized,
			   summ.SettlementDestinationID , isnull(dest.Destination , '*****') as SettlementDestination,
			   summ.RoutingDestinationID , isnull(rdest.Destination , '*****') as RoutingDestination,
			   isnull(cou.CountryID, -1) as CountryID , isnull(cou.Country , '*****') as Country,
			   summ.RatePlanID , isnull(rp.RatePlan , '******') as RatePlan,
			   summ.RatingMethodID , isnull(rm.RatingMethod , '*****') as RatingMethod,
			   summ.RoundedCallDuration , summ.ChargeDuration , summ.Amount , summ.Rate,
			   summ.RateTypeID , isnull(rti.RateItemName , '*****') as Ratetype,
			   isnull(rdb.RateDimensionBand, '*****') as RateBand,
			   summ.CurrencyID , isnull(curr.Currency , '*****') as Currency,
			   summ.INServiceLevelID , isnull(insl.ServiceLevel , '*****') as INServiceLevel,
			   Case
					 When summ.ErrorIndicator = 1 then 'Error'
					 Else 'No Error'
			   End as ErrorIndicator
		into #TempDailyINUnionOutFinancial
		from tb_DailyINUnionOutFinancial summ
		left join REFERENCESERVER.UC_REference.dbo.tb_Calltype cp on summ.CalltypeID = cp.CallTypeID
		left join REFERENCESERVER.UC_REference.dbo.tb_Destination dest on summ.SettlementDestinationID = dest.DestinationID
		left join REFERENCESERVER.UC_REference.dbo.tb_Destination rdest on summ.RoutingDestinationID = rdest.DestinationID
		left join REFERENCESERVER.UC_REference.dbo.tb_Country cou on rdest.CountryID = cou.CountryID
		left join REFERENCESERVER.UC_REference.dbo.tb_ServiceLevel insl on summ.INServiceLevelID = insl.ServiceLevelID
		left join REFERENCESERVER.UC_REference.dbo.tb_RatePlan rp on summ.RatePlanID = rp.RatePlanID
		left join REFERENCESERVER.UC_REference.dbo.tb_RatingMethod rm on summ.RatingMethodID = rm.RatingmethodID
		left join REFERENCESERVER.UC_REference.dbo.tb_RateItem rti on summ.RatetypeID = rti.RateItemID
		left join REFERENCESERVER.UC_REference.dbo.tb_Currency curr on summ.CurrencyID = curr.CurrencyID
		left join REFERENCESERVER.UC_REference.dbo.tb_RateNumberIdentifier rni on summ.RatingMethodID = rni.RatingMethodID
		                                                                     and summ.RateTypeID = rni.RateItemID
        left join REFERENCESERVER.UC_REference.dbo.tb_RateDimensionBand rdb on rni.RateDimension1BandID = rdb.RateDimensionBandID
		inner join #TempServiceLevelIDTable sltb on summ.INServiceLevelID  = sltb.ServiceLevelID
		where summ.CallDate between @StartDate and @EndDate		
		and summ.AccountID = @AccountID
		and summ.DirectionID = @DirectionID
		and summ.CalltypeID = isnull(@CallTypeID , summ.CallTypeID)
		and summ.Answered > 0

		--select *
		--from #TempDailyINUnionOutFinancial

		------------------------------------------------
		-- Get the Rates data from the Reference tables
		------------------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempRates') )
				Drop table #TempRates

        Create table #TempRates
		(
			RatePlanID int,
			RateID int,
			DestinationID int,
			BeginDate datetime,
			EndDate datetime,
			RatingMethodID int,
			CallTypeID int,
			Rate Decimal(19,6),
			RateTypeID  int
		)

        if (@DirectionID = 2) -- Outbound
		Begin

		        insert into #TempRates
				(RatePlanID ,RateID,DestinationID,BeginDate,EndDate,RatingMethodID,CallTypeID,Rate,RateTypeID)
				select rt.RatePlanID ,rt.RateID , rt.DestinationID ,rt.BeginDate , rt.EndDate , rt.RatingMethodID , rt.CallTypeID,
					   rtd.Rate , rtd.RateTypeID
				from REFERENCESERVER.UC_REference.dbo.tb_Rate rt
				inner join REFERENCESERVER.UC_REference.dbo.tb_RateDetail rtd on rt.RateID = rtd.RateID
				inner join REFERENCESERVER.UC_REference.dbo.tb_Destination dest on rt.DestinationID = dest.DestinationID
				inner join ( select distinct RatePlanID from #TempDailyINUnionOutFinancial) rp on rt.RatePlanID = rp.RatePlanID
				where dest.numberplanID > 0 -- Vendor Destinations

		End

        if (@DirectionID = 1) -- INBound
		Begin

		        insert into #TempRates
				(RatePlanID ,RateID,DestinationID,BeginDate,EndDate,RatingMethodID,CallTypeID,Rate,RateTypeID)
				select rt.RatePlanID ,rt.RateID , rt.DestinationID ,rt.BeginDate , rt.EndDate , rt.RatingMethodID , rt.CallTypeID,
					   rtd.Rate , rtd.RateTypeID
				from REFERENCESERVER.UC_REference.dbo.tb_Rate rt
				inner join REFERENCESERVER.UC_REference.dbo.tb_RateDetail rtd on rt.RateID = rtd.RateID
				inner join REFERENCESERVER.UC_REference.dbo.tb_Destination dest on rt.DestinationID = dest.DestinationID
				inner join ( select distinct RatePlanID from #TempDailyINUnionOutFinancial) rp on rt.RatePlanID = rp.RatePlanID


		End

		--select *
		--from #TempRates

		-------------------------------------------------------------------------
		-- Check to see if there are multiple currencies in the record set.
		-- In case there are multiple currencies, then everything needs to
		-- be converted to system currency
		-------------------------------------------------------------------------

		Declare @DistinctCurrency int = 0

		select @DistinctCurrency = count(*)
		from ( select distinct currencyID from #TempDailyINUnionOutFinancial ) tbl1

		------------------------------------------
		-- Create table to store the Result Set
		------------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempFinalResultSet') )
				Drop table #TempFinalResultSet

        Create table #TempFinalResultSet
		(
		   CallDate datetime , 
		   CallTypeID int ,
		   CallType varchar(60) ,
		   SettlementDestinationID int , 
		   SettlementDestination varchar(100),
		   InServiceLevelID int,
		   INServiceLevel varchar(100),
		   ErrorIndicator varchar(100), 
		   RatingMethodID int, 
	       RatingMethod varchar(100),
		   RateTypeID int, 
		   RateBand varchar(100),
		   RatePlanID int, 
		   RatePlan varchar(100),
	       Answered int,
		   OriginalCallDuration Decimal(19,2),
		   RoundedDuration Decimal(19,2),
		   Amount Decimal(19,2),
		   CurrencyID int, 
		   Currency varchar(100),
           CalcuatedRate Decimal(19,6),
           OriginalRate Decimal(19,6),
           RateBeginDate DateTime
		)
		

		if ( @DistinctCurrency > 1 )
		Begin

					   -----------------------------------------------------------------------------------------
					   -- Create table for Exchange rate, so that all data can be converted into base currency
					   -----------------------------------------------------------------------------------------

					   Declare @DefaultCurrencyID int = 1005,
					           @DefaultCurrency varchar(20) = 'USD'

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

						Insert into #TempFinalResultSet
						(
						   CallDate,  CallTypeID,   CallType,  SettlementDestinationID, 
						   SettlementDestination, INServiceLevelID , INServiceLevel,
						   ErrorIndicator,  RatingMethodID, 
						   RatingMethod,  RateTypeID,  RateBand,  RatePlanID,
						   RatePlan, Answered, OriginalCallDuration, RoundedDuration,
						   Amount, CurrencyID,  Currency, CalcuatedRate,OriginalRate,
						   RateBeginDate
						)
						select tbl1.CallDate , tbl1.CallTypeID , tbl1.CallType,
						       tbl1.SettlementDestinationID , tbl1.SettlementDestination,
							   tbl1.INServiceLevelID , tbl1.INServiceLevel,
						       tbl1.ErrorIndicator , tbl1.RatingMethodID , tbl1.RatingMethod,
							   tbl1.RateTypeID , tbl1.RateBand , tbl1.RatePlanID , tbl1.RatePlan,
							   sum(tbl1.Answered),
							   convert(Decimal(19,2),sum(tbl1.CallDuration/60.0)),
							   convert(Decimal(19,2),sum(tbl1.ChargeDuration)),
							   convert(Decimal(19,2) ,Sum(tbl1.Amount/tbl3.ExchangeRate)),
							   @DefaultCurrencyID,@DefaultCurrency,
							   Case 
								    When Sum(tbl1.ChargeDuration) = 0 then 0.0000 
									Else convert(decimal(19,6) ,sum(tbl1.Amount/tbl3.ExchangeRate)/Sum(tbl1.ChargeDuration))
								End,
							   convert(decimal(19,6) , isnull(tbl2.Rate/tbl3.ExchangeRate, 0)),
							   isnull(tbl2.BeginDate,0)					   
						from #TempDailyINUnionOutFinancial tbl1
						left join #TempRates tbl2 on tbl1.RatePlanID = tbl2.RatePlanID 
						                          and tbl1.SettlementDestinationID = tbl2.DestinationID
												  and tbl1.RatingMethodID = tbl2.RatingMethodID
												  and tbl1.CallTypeID = tbl2.CallTypeID
												  and tbl1.RateTypeID =  tbl2.RateTypeID
                        inner join #tempExchangeRate tbl3 on tbl1.CurrencyID = tbl3.CurrencyID
						Where tbl1.CallDate between isnull(tbl3.BeginDate , tbl1.CallDate)  and isnull(tbl3.EndDate , tbl1.CallDate) 
						and tbl1.CallDate between tbl2.Begindate and isnull(tbl2.EndDate , tbl1.CallDate)
						Group by tbl1.CallDate , tbl1.CallTypeID , tbl1.CallType,
						       tbl1.SettlementDestinationID , tbl1.SettlementDestination,
							   tbl1.INServiceLevelID , tbl1.INServiceLevel,
						       tbl1.ErrorIndicator , tbl1.RatingMethodID , tbl1.RatingMethod,
							   tbl1.RateTypeID , tbl1.RateBand , tbl1.RatingMethod, isnull(tbl2.BeginDate, '1900-01-01'),
							   convert(decimal(19,6) , isnull(tbl2.Rate/tbl3.ExchangeRate, 0)),
							   tbl1.RatePlanID , tbl1.RatePlan

		End

		Else
		Begin

						Insert into #TempFinalResultSet
						(
						   CallDate,  CallTypeID,   CallType,  SettlementDestinationID, 
						   SettlementDestination,   INServiceLevelID , INServiceLevel, 
						   ErrorIndicator,  RatingMethodID, 
						   RatingMethod,  RateTypeID,  RateBand,  RatePlanID,
						   RatePlan, Answered, OriginalCallDuration, RoundedDuration,
						   Amount, CurrencyID,  Currency, CalcuatedRate,OriginalRate,
						   RateBeginDate
						)
						select tbl1.CallDate , tbl1.CallTypeID , tbl1.CallType,
						       tbl1.SettlementDestinationID , tbl1.SettlementDestination,
							   tbl1.INServiceLevelID , tbl1.INServiceLevel,
						       tbl1.ErrorIndicator , tbl1.RatingMethodID , tbl1.RatingMethod,
							   tbl1.RateTypeID , tbl1.RateBand , tbl1.RatePlanID , tbl1.RatePlan,
							   sum(tbl1.Answered),
							   convert(Decimal(19,2), sum(tbl1.CallDuration/60.0)),
							   convert(Decimal(19,2), sum(tbl1.ChargeDuration)),
							   convert(Decimal(19,2) ,sum(tbl1.Amount)),
							   tbl1.CurrencyID , tbl1.Currency,
							   Case 
								    When Sum(tbl1.ChargeDuration) = 0 then 0.0000 
									Else convert(decimal(19,6) ,sum(tbl1.Amount)/Sum(tbl1.ChargeDuration))
								End,
							   convert(decimal(19,6) , isnull(tbl2.Rate, 0)),
							   isnull(tbl2.BeginDate, '1900-01-01')					   
						from #TempDailyINUnionOutFinancial tbl1
						left join #TempRates tbl2 on tbl1.RatePlanID = tbl2.RatePlanID 
						                          and tbl1.SettlementDestinationID = tbl2.DestinationID
												  and tbl1.RatingMethodID = tbl2.RatingMethodID
												  and tbl1.CallTypeID = tbl2.CallTypeID
												  and tbl1.RateTypeID =  tbl2.RateTypeID
						Where tbl1.CallDate between isnull(tbl2.Begindate , tbl1.CallDate) and isnull(tbl2.EndDate , tbl1.CallDate)
						Group by tbl1.CallDate , tbl1.CallTypeID , tbl1.CallType,
						       tbl1.SettlementDestinationID , tbl1.SettlementDestination,
							   tbl1.INServiceLevelID , tbl1.INServiceLevel,
						       tbl1.ErrorIndicator , tbl1.RatingMethodID , tbl1.RatingMethod,
							   tbl1.RateTypeID , tbl1.RateBand , tbl1.RatingMethod, isnull(tbl2.BeginDate, '1900-01-01'),
							   isnull(tbl2.Rate, 0),tbl1.RatePlanID , tbl1.RatePlan , tbl1.CurrencyID , tbl1.Currency

		End

		--------------------------------------------
		-- Display the Result set for the report
		--------------------------------------------

		select CallDate,  CallTypeID,   CallType,  
		        SettlementDestinationID, SettlementDestination,  
				INServiceLevelID , INServiceLevel,
				ErrorIndicator,  RatingMethodID, 
				RatingMethod,  RateTypeID,  RateBand,  RatePlanID,
				RatePlan, Answered, OriginalCallDuration, RoundedDuration,
				Amount, CurrencyID,  Currency, CalcuatedRate as CalculatedRate,OriginalRate,
				RateBeginDate
		from #TempFinalResultSet


		----------------------------------------------------------------
		-- Calculate the TOTAL amounts at Error Indicator Level for
		-- display in Report
		-----------------------------------------------------------------

		select @TotalErrorResult = 
		         'TOTAL' + '|' + convert(varchar(20) ,sum(Answered)) + '|' +
		          convert(varchar(20) ,sum(OriginalCallDuration)) + '|' +
		          convert(varchar(20) ,sum(RoundedDuration)) + '|' +
		          convert(varchar(20),sum(Amount))
        from #TempFinalResultSet
		where ErrorIndicator = 'Error' 
		group by ErrorIndicator

		select @TotalNoErrorResult = 
		         'TOTAL' + '|' + convert(varchar(20) ,sum(Answered)) + '|' +
		          convert(varchar(20) ,sum(OriginalCallDuration)) + '|' +
		          convert(varchar(20) ,sum(RoundedDuration)) + '|' +
		          convert(varchar(20),sum(Amount))
        from #TempFinalResultSet
		where ErrorIndicator = 'No Error'
		group by ErrorIndicator

		
End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!! While extracting Daily Partner Summary Report. '+ ERROR_MESSAGE()
		set @ResultFlag = 1
		GOTO ENDPROCESS

End Catch

--Select 'Step 4..' , getdate()

ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDailyINUnionOutFinancial') )
		Drop table #TempDailyINUnionOutFinancial

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempFinalResultSet') )
		Drop table #TempFinalResultSet

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempRates') )
		Drop table #TempRates

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempExchangeRate') )
		Drop table #tempExchangeRate
GO
