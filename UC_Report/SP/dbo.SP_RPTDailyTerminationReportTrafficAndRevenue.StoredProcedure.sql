USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_RPTDailyTerminationReportTrafficAndRevenue]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_RPTDailyTerminationReportTrafficAndRevenue]
(
    @ReportID int,
    @RunMonth int ,
	@RunYear int ,
	@IDRExchange Decimal(19,2) ,
	@CallTypeID int,
	@AccountIDList nvarchar(max),
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

Declare @MaxDateForRunMonth datetime
Declare @CurrentDate datetime  = convert(date , getdate()),
        @CurrentMonth int,
		@CurrentYear int,
		@CurrentDay int,
		@WholeMonthFactor Decimal(19,2),
		@TenDaysFactor Decimal(19,2),
		@MaxDateRunMonthDay int,
		@MinDateForRunMonth datetime,
		@TenthDateForRunMonth datetime

set @CurrentMonth = month(@CurrentDate)
set @CurrentYear = year(@CurrentDate)
set @CurrentDay = Day(@CurrentDate)
set @MinDateForRunMonth = convert(datetime , convert(varchar(4) ,@RunYear) + '-' + convert(varchar(2) ,@RunMonth) + '-' +'01')
set @TenthDateForRunMonth = convert(datetime , convert(varchar(4) ,@RunYear) + '-' + convert(varchar(2) ,@RunMonth) + '-' +'10')

set @MaxDateForRunMonth = 
    Convert( datetime,
				Convert(
						varchar(4) ,
						Case
							When @RunMonth = 12 then @RunYear + 1
							Else @RunYear
						End
					   ) + '-' +
				Convert(
						varchar(2) ,
						Case
							When @RunMonth = 12 then 1
							Else @RunMonth + 1
						End
					   ) + '-' + '01'
		  )


set @MaxDateForRunMonth = DateAdd(dd , -1 , @MaxDateForRunMonth )
set @MaxDateRunMonthDay = day(@MaxDateForRunMonth)

--select @MaxDateForRunMonth , @MinDateForRunMonth , @TenthDateForRunMonth

---------------------------------------------------------------
-- Check to see if the report is being run for a month which
-- has passed or is currently running
----------------------------------------------------------------

if ( @MaxDateForRunMonth > @CurrentDate ) -- Month is in future or still running
Begin
		
		---------------------------------------------
		-- Check to establish if the report Month is
		-- in future or is the running month
		----------------------------------------------

	    if ( (@CurrentMonth = @RunMonth) and (@CurrentYear = @RunYear) )
		Begin

				set @WholeMonthFactor = Convert(decimal(19,2) ,(@MaxDateRunMonthDay * 1.0)/@CurrentDay)

				if ( @CurrentDay < 10 ) -- Need to Extrapolate as the 10th of month is in future
				Begin

						set @TenDaysFactor = Convert(decimal(19,2) ,(10 * 1.0)/@CurrentDay)

				End
				Else -- Current Date is already passed or equal to 10th day
				Begin

						set @TenDaysFactor = 1.00

				End
		End

End

if ( @MaxDateForRunMonth <= @CurrentDate ) -- Report Month is in the past or same as current date
Begin
		
		set @WholeMonthFactor = 1.00
		set @TenDaysFactor = 1.00

End

--select 'Debug' , 
--        @WholeMonthFactor as WholeMonthFactor,
--        @TenDaysFactor as TenDaysFactor

Declare @AllAccountFlag int = 0,
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
				  GOTO PROCESSSERVICELEVEL
				  
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

		insert into #tempExchangeRate values ( 1 , -1 , @MinDateForRunMonth , NULL)


		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDailyINUnionOutFinancial') )
				Drop table #TempDailyINUnionOutFinancial


        Create table #TempDailyINUnionOutFinancial
		(
		    AccountID int,
			Account varchar(100),
			CallDate varchar(20),
            Minutes Decimal(19,2),
			AmountInUSD Decimal(19,2)
		)

        ------------------------------------------------------------------------
		-- Select the data based on the input criteria from the financial tables
		------------------------------------------------------------------------

		set @SQLStr =
		'select summ.AccountID , acc.Account,' + char(10) + 
		'substring(convert(varchar(10) ,CallDate , 120) , 9,2) ,' + char(10) +
		'sum(convert(Decimal(19,2) ,CallDuration/60.0)),' + char(10) + 
		'convert(Decimal(19,2) ,Sum(Amount/exch.ExchangeRate)) ' + char(10) +
		'from tb_DailyINUnionOutFinancial summ' + char(10) + 
		'left join REFERENCESERVER.UC_REference.dbo.tb_Account acc on summ.AccountID = acc.AccountID' + char(10) +
		'inner join #tempExchangeRate exch on summ.CurrencyID = exch.CurrencyID' + char(10) +
		'inner join #TempServiceLevelIDTable sltb on summ.INServiceLevelID  = sltb.ServiceLevelID' + char(10) +
		Case
			When @AllAccountFlag = 1 then ''
			Else ' inner join #TempAccountIDTable AccList on summ.AccountID = AccList.AccountID ' + char(10)
		End + 
		'where directionID = 1' + char(10) + -- Inbound Direction
		'and month(CallDate) =  ' + Convert(varchar(4),@RunMonth) + char(10) +
		'and year(CallDate) =  ' + Convert(varchar(4),@RunYear) + char(10) +
		'and CalltypeID = ' + char(10) +
		Case
				when @CallTypeID is NULL then ' summ.CallTypeID ' + char(10)
				else Convert(varchar(20) ,@CallTypeID) +  char(10) 
		End +	
		'and summ.CallDate between exch.BeginDate and isnull(exch.EndDate , summ.CallDate) ' +  char(10) + 		
		'group by summ.AccountID ,acc.Account , CallDate,' + char(10) +
		'substring(convert(varchar(10) ,CallDate , 120) , 9,2)'

		--print @SQLStr

		insert into #TempDailyINUnionOutFinancial
		Exec (@SQLStr)

		--select *
		--from #TempDailyINUnionOutFinancial

		-----------------------------------------------------------------------------
		-- Pivot the extracted data based on the Call Date to create the final data
		-- set
		-----------------------------------------------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempTotalMinutesByDay') )
			Drop table #TempTotalMinutesByDay

        select AccountID , Account , CallDate ,Minutes
		into #TempTotalMinutesByDay
		from #TempDailyINUnionOutFinancial

		--select * from #TempTotalMinutesByDay

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempTotalMinutesByDayPivot') )
			Drop table #TempTotalMinutesByDayPivot

        select *
		into #TempTotalMinutesByDayPivot
		from
		(
				SELECT   AccountID ,Account,  [01] , [02] , [03] , [04] , [05] , [06] , [07],
						 [08] , [09] , [10] , [11] , [12] , [13] , [14] , [15] , [16] , [17] , [18],
						 [19] , [20] , [21] , [22] , [23] , [24] , [25] , [26] , [27] , [28], [29],
						 [30] , [31]
				FROM  #TempTotalMinutesByDay
				PIVOT
				(
					   SUM(Minutes) 
					   FOR CallDate IN 
					   (
						 [01] , [02] , [03] , [04] , [05] , [06] , [07],
						 [08] , [09] , [10] , [11] , [12] , [13] , [14] , 
						 [15] , [16] , [17] , [18], [19] , [20] , [21] ,
						 [22] , [23] , [24] , [25] , [26] , [27] , [28],
						 [29],[30] , [31]
					   )
				) AS PivotTable
		) as Tbl1

		--select *
		--from #TempTotalMinutesByDayPivot

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempTrafficExtrapolate') )
				Drop table #TempTrafficExtrapolate

        Create table #TempTrafficExtrapolate
		(
			AccountID int,
			Account varchar(100),
			WholeMonthMinutes Decimal(19,2),
			TenDaysMinutes Decimal(19,2),
			EstimatedRevenue Decimal(19,2),
			Rate Decimal(19,6)
		)

		-------------------------------------------------------------------------
		-- Depending on the value of the factor, extract minutes for whole month
		-- and 10 days
		-------------------------------------------------------------------------

		insert into #TempTrafficExtrapolate
		( AccountID , Account , WholeMonthMinutes , Rate )
        select AccountID , Account ,
		       convert(decimal(19,2) ,Sum(Minutes) * @WholeMonthFactor) ,
			   Case
					When Sum(Minutes) = 0 then 0
					Else convert(decimal(19,6) , Sum(AmountInUSD)/Sum(Minutes))
			   End		       
		from #TempDailyINUnionOutFinancial tbl1
		Group by  AccountID , Account

		update #TempTrafficExtrapolate
		set EstimatedRevenue = (WholeMonthMinutes * Rate * @IDRExchange)/1000

		--select *
		--from #TempTrafficExtrapolate

		---------------------------------------------------------------------
		--  Depending on the value of the Ten day Factor, decidde whether to
		--  pick up actual minutes or extrapolated minutes
		---------------------------------------------------------------------

		if ( @TenDaysFactor = 1.00 ) -- Actual Numbers
		Begin

					update tbl1
					set TenDaysMinutes = tbl2.Minutes
					from #TempTrafficExtrapolate tbl1
					inner join 
					(
					    select AccountID , account , Sum(Minutes) as Minutes
					    from #TempDailyINUnionOutFinancial 
						where convert(datetime , convert(varchar(4) ,@RunYear) + '-' + convert(varchar(2) ,@RunMonth) + '-' + CallDate)
						      between @MinDateForRunMonth and @TenthDateForRunMonth
						Group by AccountID , Account

					) tbl2 on tbl1.AccountID = tbl2.AccountID


		End
		Else -- Extrapolate and get the approximate numbers
		Begin


					update tbl1
					set TenDaysMinutes = tbl2.Minutes
					from #TempTrafficExtrapolate tbl1
					inner join 
					(
					    select AccountID , account , convert(decimal(19,2) ,Sum(Minutes) * @TenDaysFactor) as Minutes
					    from #TempDailyINUnionOutFinancial
						group by AccountID , account
						 
					) tbl2 on tbl1.AccountID = tbl2.AccountID

		End

	    --select *
		--from #TempTrafficExtrapolate

		--------------------------------------------------------------------
		-- Assemble all the data to display the result set for report
		--------------------------------------------------------------------

		select tbl1.Account , isnull(tbl1.EstimatedRevenue,0) as 'EstRevenue',
		       tbl1.Rate , isnull(tbl1.WholeMonthMinutes, 0) as 'MinutesForWholeMonth' ,
			   isnull(tbl1.TenDaysMinutes,0) as 'Minutesfor10Days',
			   isnull(tbl2.[01] , 0) as '_01', isnull(tbl2.[02] , 0) as '_02',  isnull(tbl2.[03] , 0) as '_03',
			   isnull(tbl2.[04] , 0) as '_04', isnull(tbl2.[05] , 0) as '_05',  isnull(tbl2.[06] , 0) as '_06',
			   isnull(tbl2.[07] , 0) as '_07', isnull(tbl2.[08] , 0) as '_08',  isnull(tbl2.[09] , 0) as '_09',
			   isnull(tbl2.[10] , 0) as '_10', isnull(tbl2.[11] , 0) as '_11',  isnull(tbl2.[12] , 0) as '_12',
			   isnull(tbl2.[13] , 0) as '_13', isnull(tbl2.[14] , 0) as '_14',  isnull(tbl2.[15] , 0) as '_15',
			   isnull(tbl2.[16] , 0) as '_16', isnull(tbl2.[17] , 0) as '_17',  isnull(tbl2.[18] , 0) as '_18',
			   isnull(tbl2.[19] , 0) as '_19', isnull(tbl2.[20] , 0) as '_20',  isnull(tbl2.[21] , 0) as '_21',
			   isnull(tbl2.[22] , 0) as '_22', isnull(tbl2.[23] , 0) as '_23',  isnull(tbl2.[24] , 0) as '_24',
			   isnull(tbl2.[25] , 0) as '_25', isnull(tbl2.[26] , 0) as '_26',  isnull(tbl2.[27] , 0) as '_27',
			   isnull(tbl2.[28] , 0) as '_28', isnull(tbl2.[29] , 0) as '_29',  isnull(tbl2.[30] , 0) as '_30',
			   isnull(tbl2.[31] , 0) as '_31'
		from #TempTrafficExtrapolate tbl1
		inner join #TempTotalMinutesByDayPivot tbl2 on tbl1.AccountID = tbl2.AccountID
		order by tbl1.Account

		----------------------------------------------------------------------
		-- Calculate TOTAL of the above result set to display in the Report
		----------------------------------------------------------------------

	select @TotalResult = 
			   'TOTAL' + '|' + 
		       convert(varchar(100) ,sum(isnull(tbl1.EstimatedRevenue,0))) + '|' +
		       '' + '|' +
			   convert(varchar(100) ,sum(isnull(tbl1.WholeMonthMinutes, 0))) + '|' +
			   convert(varchar(100) ,sum(isnull(tbl1.TenDaysMinutes,0))) + '|' +
			   convert(varchar(100) ,sum(isnull(tbl2.[01] , 0))) + '|' + 
			   convert(varchar(100) ,sum(isnull(tbl2.[02] , 0))) + '|' + 
			   convert(varchar(100) ,sum(isnull(tbl2.[03] , 0))) + '|' +
			   convert(varchar(100) ,sum(isnull(tbl2.[04] , 0))) + '|' +
			   convert(varchar(100) ,sum(isnull(tbl2.[05] , 0))) + '|' + 
			   convert(varchar(100) ,sum(isnull(tbl2.[06] , 0))) + '|' +
			   convert(varchar(100) ,sum(isnull(tbl2.[07] , 0))) + '|' +
			   convert(varchar(100) ,sum(isnull(tbl2.[08] , 0))) + '|' + 
			   convert(varchar(100) ,sum(isnull(tbl2.[09] , 0))) + '|' +
			   convert(varchar(100) ,sum(isnull(tbl2.[10] , 0))) + '|' +
			   convert(varchar(100) ,sum(isnull(tbl2.[11] , 0))) + '|' + 
			   convert(varchar(100) ,sum(isnull(tbl2.[12] , 0))) + '|' +
			   convert(varchar(100) ,sum(isnull(tbl2.[13] , 0))) + '|' + 
			   convert(varchar(100) ,sum(isnull(tbl2.[14] , 0))) + '|' +  
			   convert(varchar(100) ,sum(isnull(tbl2.[15] , 0))) + '|' +
			   convert(varchar(100) ,sum(isnull(tbl2.[16] , 0))) + '|' +
			   convert(varchar(100) ,sum(isnull(tbl2.[17] , 0))) + '|' + 
			   convert(varchar(100) ,sum(isnull(tbl2.[18] , 0))) + '|' +
			   convert(varchar(100) ,sum(isnull(tbl2.[19] , 0))) + '|' + 
			   convert(varchar(100) ,sum(isnull(tbl2.[20] , 0))) + '|' + 
			   convert(varchar(100) ,sum(isnull(tbl2.[21] , 0))) + '|' +
			   convert(varchar(100) ,sum(isnull(tbl2.[22] , 0))) + '|' + 
			   convert(varchar(100) ,sum(isnull(tbl2.[23] , 0))) + '|' +
			   convert(varchar(100) ,sum(isnull(tbl2.[24] , 0))) + '|' +
			   convert(varchar(100) ,sum(isnull(tbl2.[25] , 0))) + '|' +
			   convert(varchar(100) ,sum(isnull(tbl2.[26] , 0))) + '|' +  
			   convert(varchar(100) ,sum(isnull(tbl2.[27] , 0))) + '|' +
			   convert(varchar(100) ,sum(isnull(tbl2.[28] , 0))) + '|' +
			   convert(varchar(100) ,sum(isnull(tbl2.[29] , 0))) + '|' + 
			   convert(varchar(100) ,sum(isnull(tbl2.[30] , 0))) + '|' +
			   convert(varchar(100) ,sum(isnull(tbl2.[31] , 0)))
		from #TempTrafficExtrapolate tbl1
		inner join #TempTotalMinutesByDayPivot tbl2 on tbl1.AccountID = tbl2.AccountID

		if ( @TotalResult is NULL )
		Begin

					select @TotalResult = 
							   'TOTAL' + '|' + '0.00' + '|' +
		       					   '' + '|' +  '0.00' + '|' + '0.00'+ '|' +
							   '0.00' + '|' + '0.00' + '|' + '0.00' + '|' +
							   '0.00' + '|' + '0.00' + '|' + '0.00' + '|' +
							   '0.00' + '|' + '0.00' + '|' + '0.00' + '|' +
							   '0.00' + '|' + '0.00' + '|' + '0.00' + '|' +
							   '0.00' + '|' + '0.00' + '|' + '0.00' + '|' +
							   '0.00' + '|' + '0.00' + '|' + '0.00' + '|' +
							   '0.00' + '|' + '0.00' + '|' + '0.00' + '|' +
							   '0.00' + '|' + '0.00' + '|' + '0.00' + '|' +
							   '0.00' + '|' + '0.00' + '|' + '0.00' + '|' +
							   '0.00' + '|' + '0.00' + '|' + '0.00' + '|' +
							   '0.00'

		End




End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!! While extracting Daily Termination Report (Traffic & Revenue). '+ ERROR_MESSAGE()
		set @ResultFlag = 1
		GOTO ENDPROCESS

End Catch

--Select 'Step 4..' , getdate()

ENDPROCESS:


if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAccountIDTable') )
		Drop table #TempAccountIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCommercialTrunkIDTable') )
		Drop table #TempCommercialTrunkIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDailyINUnionOutFinancial') )
		Drop table #TempDailyINUnionOutFinancial

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempTotalMinutesByDay') )
		Drop table #TempTotalMinutesByDay

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempTotalMinutesByDayPivot') )
		Drop table #TempTotalMinutesByDayPivot

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempExchangeRate') )
		Drop table #tempExchangeRate
GO
