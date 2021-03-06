USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_RPTCostSavingReport]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_RPTCostSavingReport]
(
    @ReportID int,
    @RefMonth int ,
	@RefYear int ,
    @CompMonth int ,
	@CompYear int ,
	@CallTypeID int,
	@CountryIDList nvarchar(max),
	@ServiceLevelIDList nvarchar(max),
	@TotalResult nvarchar(max) Output,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

---------------------------------------------------------
-- Check if the Report is valid and exists in he system
---------------------------------------------------------

if not exists ( select 1 from tb_Report where ReportID = @ReportID and Flag & 1 <> 1 )
Begin

		set @ErrorDescription = 'ERROR !!! Report ID is not valid or is not active (flag <> 0)'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End

Declare @RefStartDate Datetime,
        @RefEndDate DateTime,
		@CompStartDate DateTime,
		@CompEndDate DateTime

set @RefStartDate = convert(datetime , convert(varchar(4) ,@RefYear) + '-' + convert(varchar(2) ,@RefMonth) + '-' +'01')
set @CompStartDate = convert(datetime , convert(varchar(4) ,@CompYear) + '-' + convert(varchar(2) ,@CompMonth) + '-' +'01')

set @RefEndDate = 
    Convert( datetime,
				Convert(
						varchar(4) ,
						Case
							When @RefMonth = 12 then @RefYear + 1
							Else @RefYear
						End
					   ) + '-' +
				Convert(
						varchar(2) ,
						Case
							When @RefMonth = 12 then 1
							Else @RefMonth + 1
						End
					   ) + '-' + '01'
		  )


set @RefEndDate = DateAdd(dd , -1 , @RefEndDate )

set @CompEndDate = 
    Convert( datetime,
				Convert(
						varchar(4) ,
						Case
							When @CompMonth = 12 then @CompYear + 1
							Else @CompYear
						End
					   ) + '-' +
				Convert(
						varchar(2) ,
						Case
							When @CompMonth = 12 then 1
							Else @CompMonth + 1
						End
					   ) + '-' + '01'
		  )


set @CompEndDate = DateAdd(dd , -1 , @CompEndDate )

--select @RefStartDate , @RefEndDate , @CompStartDate , @CompEndDate

--select 'Debug' , 
--        @WholeMonthFactor as WholeMonthFactor,
--        @TenDaysFactor as TenDaysFactor

Declare @AllCountryFlag int = 0,
        @AllServiceLevelFlag int = 0,
		@SQLStr1 nvarchar(max),
		@SQLStr2 nvarchar(max),
		@SQLStr3 nvarchar(max),
		@SQLStr  nvarchar(max)

-------------------------------------------------------------
-- Set the CALL TYPE to NULL in case the value passed is 0
-- indicating that all CALL TYPE need to be considered
-------------------------------------------------------------

if ( @CallTypeID = 0 )
	set @CallTypeID = NULL


Begin Try

-----------------------------------------------------------------
-- Create table for list of selected Countries from the parameter
-- passed
-----------------------------------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCountryIDTable') )
				Drop table #TempCountryIDTable

		Create Table #TempCountryIDTable (CountryID varchar(100) )


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
		-- Check if the All the Accounts have been selected 
		------------------------------------------------------

		if exists (
						select 1 
						from #TempCountryIDTable 
						where CountryID = 0
				  )
		Begin

                  set @AllCountryFlag = 1
				  GOTO GETSERVICELEVEL
				  
		End
		
        -----------------------------------------------------------------
		-- Check to ensure that all the Account IDs passed are valid values
		-----------------------------------------------------------------
		
		if exists ( 
						select 1 
						from #TempCountryIDTable 
						where CountryID not in
						(
							Select CountryID
							from ReferenceServer.UC_Reference.dbo.tb_Country
							where flag & 1 <> 1
						)
					)
		Begin

			set @ErrorDescription = 'ERROR !!! List of Country IDs passed contain value(s) which are not valid or do not exist'
			set @ResultFlag = 1
			GOTO ENDPROCESS

		End


GETSERVICELEVEL:

----------------------------------------------------------------------
-- Create table for list of selected Service Level from the parameter
-- passed
----------------------------------------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempServiceLevelIDTable') )
				Drop table #TempServiceLevelIDTable

		Create Table #TempServiceLevelIDTable (ServiceLevelID varchar(100) )


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
		-- Check if the All the Accounts have been selected 
		------------------------------------------------------

		if exists (
						select 1 
						from #TempServiceLevelIDTable 
						where ServiceLevelID = 0
				  )
		Begin

                  set @AllServiceLevelFlag = 1
				  GOTO GENERATEREPORT
				  
		End
		
        -----------------------------------------------------------------
		-- Check to ensure that all the Account IDs passed are valid values
		-----------------------------------------------------------------
		
		if exists ( 
						select 1 
						from #TempServiceLevelIDTable 
						where ServiceLevelID not in
						(
							Select ServiceLevelID
							from ReferenceServer.UC_Reference.dbo.tb_ServiceLevel
							where flag & 1 <> 1
						)
					)
		Begin

			set @ErrorDescription = 'ERROR !!! List of ServiceLEvel IDs passed contain value(s) which are not valid or do not exist'
			set @ResultFlag = 1
			GOTO ENDPROCESS

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

		insert into #tempExchangeRate values ( 1 , -1 , '2000-01-01' , NULL)

		------------------------------------------------------------------
		-- Extract data for the Reference month from the Financial table
		------------------------------------------------------------------

		select summ.CallDate ,
			   isnull(cou.CountryID, -1) as CountryID , isnull(cou.Country , '*****') as Country,
			   summ.INServiceLevelID , isnull(insl.ServiceLevel , '*****') as INServiceLevel,
			   summ.CallDuration,
			   summ.ChargeDuration ,summ.Amount,
			   summ.CurrencyID , isnull(curr.Currency , '*****') as Currency
		into #TempRefINUnionOutFinancial
		from tb_DailyINUnionOutFinancial summ
		left join REFERENCESERVER.UC_REference.dbo.tb_Destination rdest on summ.RoutingDestinationID = rdest.DestinationID
		left join REFERENCESERVER.UC_REference.dbo.tb_Country cou on rdest.CountryID = cou.CountryID
		left join REFERENCESERVER.UC_REference.dbo.tb_ServiceLevel insl on summ.INServiceLevelID = insl.ServiceLevelID
		left join REFERENCESERVER.UC_REference.dbo.tb_Currency curr on summ.CurrencyID = curr.CurrencyID
		where CallDate between @RefStartDate and @RefEndDate
		and summ.DirectionID = 2
		and summ.CallTypeID = isnull(@CallTypeID , summ.CalltypeID)


		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempRefDataSet') )
				Drop table #TempRefDataSet


        Create table #TempRefDataSet
		(
		    CountryID int,
			Country varchar(100),
			OriginalMinutes Decimal(19,2),
            Minutes Decimal(19,2),
			AmountInUSD Decimal(19,2)
		)

        ------------------------------------------------------------------------
		-- Select the data based on the input criteria from the financial tables
		------------------------------------------------------------------------

		set @SQLStr =
		'select summ.CountryID , summ.Country,' + char(10) + 
		'convert(Decimal(19,2) ,sum(CallDuration/60.0)),' + char(10) + 
		'sum(convert(Decimal(19,2) ,ChargeDuration)),' + char(10) + 
		'convert(Decimal(19,2) ,Sum(Amount/exch.ExchangeRate)) ' + char(10) +
		'from #TempRefINUnionOutFinancial summ' + char(10) + 
		'inner join #tempExchangeRate exch on summ.CurrencyID = exch.CurrencyID' + char(10) +
		Case
			When @AllCountryFlag = 1 then ''
			Else ' inner join #TempCountryIDTable CouList on summ.CountryID = CouList.CountryID ' + char(10)
		End + 
		Case
			When @AllServiceLevelFlag = 1 then ''
			Else ' inner join #TempServiceLevelIDTable ServLevelList on summ.INServiceLevelID = ServLevelList.ServiceLevelID ' + char(10)
		End + 
		'where summ.CallDate between exch.BeginDate and isnull(exch.EndDate , summ.CallDate) ' +  char(10) + 		
		'Group by summ.CountryId , summ.Country'
		

		--print @SQLStr

		insert into #TempRefDataSet
		Exec (@SQLStr)

		--select *
		--from #TempRefDataSet

		------------------------------------------------------------------
		-- Extract data for the comparison month from the Financial table
		------------------------------------------------------------------

		select summ.CallDate ,
			   isnull(cou.CountryID, -1) as CountryID , isnull(cou.Country , '*****') as Country,
			   summ.INServiceLevelID , isnull(insl.ServiceLevel , '*****') as INServiceLevel,
			   summ.CallDuration,
			   summ.ChargeDuration ,summ.Amount,
			   summ.CurrencyID , isnull(curr.Currency , '*****') as Currency
		into #TempCompINUnionOutFinancial
		from tb_DailyINUnionOutFinancial summ
		left join REFERENCESERVER.UC_REference.dbo.tb_Destination rdest on summ.RoutingDestinationID = rdest.DestinationID
		left join REFERENCESERVER.UC_REference.dbo.tb_Country cou on rdest.CountryID = cou.CountryID
		left join REFERENCESERVER.UC_REference.dbo.tb_ServiceLevel insl on summ.INServiceLevelID = insl.ServiceLevelID
		left join REFERENCESERVER.UC_REference.dbo.tb_Currency curr on summ.CurrencyID = curr.CurrencyID
		where CallDate between @CompStartDate and @CompEndDate
		and summ.DirectionID = 2
		and summ.CallTypeID = isnull(@CallTypeID , summ.CalltypeID)


		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCompDataSet') )
				Drop table #TempCompDataSet


        Create table #TempCompDataSet
		(
		    CountryID int,
			Country varchar(100),
			OriginalMinutes Decimal(19,2),
            Minutes Decimal(19,2),
			AmountInUSD Decimal(19,2)
		)

        ------------------------------------------------------------------------
		-- Select the data based on the input criteria from the financial tables
		------------------------------------------------------------------------

		set @SQLStr =
		'select summ.CountryID , summ.Country,' + char(10) + 
		'convert(Decimal(19,2) ,sum(CallDuration/60.0)),' + char(10) + 
		'sum(convert(Decimal(19,2) ,ChargeDuration)),' + char(10) + 
		'convert(Decimal(19,2) ,Sum(Amount/exch.ExchangeRate)) ' + char(10) +
		'from #TempCompINUnionOutFinancial summ' + char(10) + 
		'inner join #tempExchangeRate exch on summ.CurrencyID = exch.CurrencyID' + char(10) +
		Case
			When @AllCountryFlag = 1 then ''
			Else ' inner join #TempCountryIDTable CouList on summ.CountryID = CouList.CountryID ' + char(10)
		End + 
		Case
			When @AllServiceLevelFlag = 1 then ''
			Else ' inner join #TempServiceLevelIDTable ServLevelList on summ.INServiceLevelID = ServLevelList.ServiceLevelID ' + char(10)
		End + 
		'where summ.CallDate between exch.BeginDate and isnull(exch.EndDate , summ.CallDate) ' +  char(10) + 		
		'Group by summ.CountryId , summ.Country'
		

		--print @SQLStr

		insert into #TempCompDataSet
		Exec (@SQLStr)

		--select *
		--from #TempCompDataSet

		---------------------------------------------------------------------
		-- Create the table fro final Result set by joining information from
		-- Reference and Comparison Months
		-----------------------------------------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempFinalDataSet') )
				Drop table #TempFinalDataSet

        Create table #TempFinalDataSet
		(
			CountryID int,
			Country varchar(100),
			RefMonthOriginalMinutes Decimal(19,2),
			RefMonthChargeMinutes Decimal(19,2),
			RefMonthAmount Decimal(19,2),
			RefMonthRate Decimal(19,4),
			CompMonthOriginalMinutes Decimal(19,2),
			CompMonthChargeMinutes Decimal(19,2),
			CompMonthAmount Decimal(19,2),
			CompMonthRate Decimal(19,4),
			PercentIncrementalTraffic Decimal(19,2),
			CostSavings Decimal(19,2),
			PercentCostSavings Decimal(19,2)
		)

		insert into #TempFinalDataSet
		(
		  CountryID , Country , RefMonthOriginalMinutes, RefMonthChargeMinutes , RefMonthAmount , RefMonthRate,
		  CompMonthOriginalMinutes ,CompMonthChargeMinutes , CompMonthAmount , CompMonthRate
		)
		Select tbl1.CountryID , tbl2.Country,
		       tbl1.OriginalMinutes,
		       tbl1.Minutes , tbl1.AmountInUSD,
			   Case
					When tbl1.Minutes = 0 then 0
					Else convert(decimal(19,4) ,tbl1.AmountInUSD/tbl1.Minutes)					
			   End,
			   tbl2.OriginalMinutes,
			   tbl2.Minutes,
			   tbl2.AmountInUSD,
			   Case
					When tbl2.Minutes = 0 then 0
					Else convert(decimal(19,4) ,tbl2.AmountInUSD/tbl2.Minutes)					
			   End
		from #TempRefDataSet tbl1
		inner join #TempCompDataSet tbl2 on tbl1.CountryID = tbl2.CountryID


		-------------------------------------------------------------
		-- Update other comparison parameters for analysis of data
		-------------------------------------------------------------

		update #TempFinalDataSet
		set PercentIncrementalTraffic = 
		    Case
			      When CompMonthChargeMinutes = 0 then  0
			      Else convert(decimal(19,2) ,((RefMonthChargeMinutes - CompMonthChargeMinutes)/CompMonthChargeMinutes)*100)
			End,
			CostSavings = convert(Decimal(19,2) ,(CompMonthRate - RefMonthRate ) * RefMonthChargeMinutes),
			PercentCostSavings =
		    Case
			      When CompMonthRate = 0 then  0
			      Else convert(decimal(19,2) ,((CompMonthRate - RefMonthRate )/CompMonthRate)*100)
			End

		Select *
		from #TempFinalDataSet
		order by RefMonthChargeMinutes Desc

        --------------------------------------------------------------------
		-- Calculate the TOTAL for the above result set to display in the 
		-- report
		--------------------------------------------------------------------

		Declare @TotalRefMonthRate Decimal(19,4),
		        @TotalCompMonthRate Decimal(19,4)

        select @TotalRefMonthRate =
			   Case
					When sum(RefMonthChargeMinutes) = 0 then 0
					Else convert(decimal(19,4) ,sum(RefMonthAmount)/sum(RefMonthChargeMinutes))					
			   End,
			   @TotalCompMonthRate = 
			   Case
					When sum(CompMonthChargeMinutes) = 0 then 0
					Else convert(decimal(19,4) ,sum(CompMonthAmount)/sum(CompMonthChargeMinutes))					
			   End
		from #TempFinalDataSet

		--select @TotalRefMonthRate , @TotalCompMonthRate

		Select @TotalResult = 
		     'TOTAL' + '|' +
			 convert(varchar(100) ,sum(RefMonthOriginalMinutes)) + '|' +
			 convert(varchar(100) ,sum(RefMonthChargeMinutes)) + '|' +
			 convert(varchar(100) ,sum(RefMonthAmount)) + '|' +
			 convert(varchar(100) , @TotalRefMonthRate) + '|' +
			 convert(varchar(100) ,sum(CompMonthOriginalMinutes)) + '|' +
			 convert(varchar(100) ,sum(CompMonthChargeMinutes)) + '|' +
			 convert(varchar(100) ,sum(CompMonthAmount)) + '|' +
			 convert(varchar(100) , @TotalCompMonthRate) + '|' +
			 convert(varchar(100),
		     Case
			      When sum(CompMonthChargeMinutes) = 0 then  0
			      Else convert(decimal(19,2) ,((sum(RefMonthChargeMinutes) - sum(CompMonthChargeMinutes))/sum(CompMonthChargeMinutes))*100)
			 End ) + '|' +
			 convert(varchar(100) ,convert(decimal(19,2) ,(@TotalCompMonthRate -  @TotalRefMonthRate) * sum(RefMonthChargeMinutes))) + '|' +
			 convert( varchar(100),
		    Case
			      When @TotalCompMonthRate = 0 then  0
			      Else convert(decimal(19,2) ,((@TotalCompMonthRate - @TotalRefMonthRate )/@TotalCompMonthRate)*100)
			End)
        from #TempFinalDataSet


End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!! While extracting Cost Saving Report. '+ ERROR_MESSAGE()
		set @ResultFlag = 1
		GOTO ENDPROCESS

End Catch

--Select 'Step 4..' , getdate()

ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempRefINUnionOutFinancial') )
		Drop table #TempRefINUnionOutFinancial

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCompINUnionOutFinancial') )
		Drop table #TempCompINUnionOutFinancial

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCountryIDTable') )
		Drop table #TempCountryIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempServiceLevelIDTable') )
		Drop table #TempServiceLevelIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempRefDataSet') )
		Drop table #TempRefDataSet

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCompDataSet') )
		Drop table #TempCompDataSet

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempFinalDataSet') )
		Drop table #TempFinalDataSet

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempExchangeRate') )
		Drop table #tempExchangeRate
GO
