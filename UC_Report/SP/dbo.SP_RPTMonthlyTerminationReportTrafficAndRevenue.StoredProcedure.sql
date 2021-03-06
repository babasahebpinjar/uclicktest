USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_RPTMonthlyTerminationReportTrafficAndRevenue]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_RPTMonthlyTerminationReportTrafficAndRevenue]
(
    @ReportID int,
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
		@TenthDateForRunMonth datetime,
		@RunMonth int = Month(getdate()),
		@RunMonthName varchar(10)

set @CurrentMonth = month(@CurrentDate)
set @CurrentYear = year(@CurrentDate)
set @CurrentDay = Day(@CurrentDate)
set @MinDateForRunMonth = convert(datetime , convert(varchar(4) ,@RunYear) + '-' + '01' + '-' +'01')

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

set @RunMonthName = Case
						When @RunMonth = 1 then 'Jan'
						When @RunMonth = 2 then 'Feb'
						When @RunMonth = 3 then 'Mar'
						When @RunMonth = 4 then 'Apr'
						When @RunMonth = 5 then 'May'
						When @RunMonth = 6 then 'Jun' 
						When @RunMonth = 7 then 'Jul'
						When @RunMonth = 8 then 'Aug'
						When @RunMonth = 9 then 'Sep' 
						When @RunMonth = 10 then 'Oct' 
						When @RunMonth = 11 then 'Nov'
						When @RunMonth = 12 then 'Dec' 
					End

--select @MaxDateForRunMonth , @MinDateForRunMonth , @TenthDateForRunMonth

---------------------------------------------------------------
-- Check to see if the current date is less than the Max date
-- for the month. This is to establish, if we need to extrapolate 
-- or report the exact numbers for the month
----------------------------------------------------------------

if ( @MaxDateForRunMonth > @CurrentDate ) -- Month is in future or still running
Begin

		set @WholeMonthFactor = Convert(decimal(19,2) ,(@MaxDateRunMonthDay * 1.0)/@CurrentDay)
		
End

Else
Begin
		
		set @WholeMonthFactor = 1.00

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
			CallMonth varchar(20),
            Minutes Decimal(19,2),
			AmountInUSD Decimal(19,2)
		)

        ------------------------------------------------------------------------
		-- Select the data based on the input criteria from the financial tables
		------------------------------------------------------------------------

		set @SQLStr =
		'select summ.AccountID , acc.Account,' + char(10) + 
		'       Case ' + char(10) +
		'			When Month(CallDate) = 1 then ''Jan''' + char(10) + 
		'			When Month(CallDate) = 2 then ''Feb''' + char(10) + 
		'			When Month(CallDate) = 3 then ''Mar''' + char(10) + 
		'			When Month(CallDate) = 4 then ''Apr''' + char(10) + 
		'			When Month(CallDate) = 5 then ''May''' + char(10) + 
		'			When Month(CallDate) = 6 then ''Jun''' + char(10) + 
		'			When Month(CallDate) = 7 then ''Jul''' + char(10) + 
		'			When Month(CallDate) = 8 then ''Aug''' + char(10) + 
		'			When Month(CallDate) = 9 then ''Sep''' + char(10) + 
		'			When Month(CallDate) = 10 then ''Oct''' + char(10) + 
		'			When Month(CallDate) = 11 then ''Nov''' + char(10) + 
		'			When Month(CallDate) = 12 then ''Dec''' + char(10) + 
		'	   End, ' + char(10) + 
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
		'and year(CallDate) =  ' + Convert(varchar(4),@RunYear) + char(10) +
		'and CalltypeID = ' + char(10) +
		Case
				when @CallTypeID is NULL then ' summ.CallTypeID ' + char(10)
				else Convert(varchar(20) ,@CallTypeID) +  char(10) 
		End +	
		'and summ.CallDate between exch.BeginDate and isnull(exch.EndDate , summ.CallDate) ' +  char(10) + 		
		'group by summ.AccountID ,acc.Account ,' + char(10) +
		'       Case ' + char(10) +
		'			When Month(CallDate) = 1 then ''Jan''' + char(10) + 
		'			When Month(CallDate) = 2 then ''Feb''' + char(10) + 
		'			When Month(CallDate) = 3 then ''Mar''' + char(10) + 
		'			When Month(CallDate) = 4 then ''Apr''' + char(10) + 
		'			When Month(CallDate) = 5 then ''May''' + char(10) + 
		'			When Month(CallDate) = 6 then ''Jun''' + char(10) + 
		'			When Month(CallDate) = 7 then ''Jul''' + char(10) + 
		'			When Month(CallDate) = 8 then ''Aug''' + char(10) + 
		'			When Month(CallDate) = 9 then ''Sep''' + char(10) + 
		'			When Month(CallDate) = 10 then ''Oct''' + char(10) + 
		'			When Month(CallDate) = 11 then ''Nov''' + char(10) + 
		'			When Month(CallDate) = 12 then ''Dec''' + char(10) + 
		'	   End'

		--print @SQLStr

		insert into #TempDailyINUnionOutFinancial
		Exec (@SQLStr)

		--select *
		--from #TempDailyINUnionOutFinancial

		--------------------------------------------------------------------------------
		-- Update the numbers of the month for current date, based on the value of
		-- the factor
		--------------------------------------------------------------------------------
		 update #TempDailyINUnionOutFinancial
		 set Minutes = convert(decimal(19,2) ,Minutes * @WholeMonthFactor),
		     AmountInUSD = convert(decimal(19,2) ,AmountInUSD * @WholeMonthFactor)
         where CallMonth = @RunMonthName

		--select *
		--from #TempDailyINUnionOutFinancial

		-----------------------------------------------------------------------------
		-- Pivot the extracted data based on the Call Month to create the final data
		-- set for Minutes
		-----------------------------------------------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempTotalMinutesByMonth') )
			Drop table #TempTotalMinutesByMonth

        select AccountID , Account , CallMonth ,Minutes
		into #TempTotalMinutesByMonth
		from #TempDailyINUnionOutFinancial

		--select * from #TempTotalMinutesByMonth

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempTotalMinutesByMonthPivot') )
			Drop table #TempTotalMinutesByMonthPivot

        select *
		into #TempTotalMinutesByMonthPivot
		from
		(
				SELECT   AccountID ,Account,  [Jan] , [Feb] , [Mar] , [Apr] , [May] , [Jun] , [Jul],
						 [Aug] , [Sep] , [Oct] , [Nov] , [Dec] 
				FROM  #TempTotalMinutesByMonth
				PIVOT
				(
					   SUM(Minutes) 
					   FOR CallMonth IN 
					   (
						 [Jan] , [Feb] , [Mar] , [Apr] , 
						 [May] , [Jun] , [Jul],	 [Aug] , 
						 [Sep] , [Oct] , [Nov] , [Dec]
					   )
				) AS PivotTable
		) as Tbl1

		--select *
		--from #TempTotalMinutesByMonthPivot

		-----------------------------------------------------------------------------
		-- Pivot the extracted data based on the Call Month to create the final data
		-- set for Amoutn in USD
		-----------------------------------------------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempTotalAmountByMonth') )
			Drop table #TempTotalAmountByMonth

        select AccountID , Account , CallMonth ,convert(decimal(19,2) ,(AmountInUSD * @IDRExchange)/1000 ) as Amount
		into #TempTotalAmountByMonth
		from #TempDailyINUnionOutFinancial

		--select * from #TempTotalAmountByMonth

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempTotalAmountByMonthPivot') )
			Drop table #TempTotalAmountByMonthPivot

        select *
		into #TempTotalAmountByMonthPivot
		from
		(
				SELECT   AccountID ,Account,  [Jan] , [Feb] , [Mar] , [Apr] , [May] , [Jun] , [Jul],
						 [Aug] , [Sep] , [Oct] , [Nov] , [Dec] 
				FROM  #TempTotalAmountByMonth
				PIVOT
				(
					   SUM(Amount) 
					   FOR CallMonth IN 
					   (
						 [Jan] , [Feb] , [Mar] , [Apr] , 
						 [May] , [Jun] , [Jul],	 [Aug] , 
						 [Sep] , [Oct] , [Nov] , [Dec]
					   )
				) AS PivotTable
		) as Tbl1

		--select *
		--from #TempTotalAmountByMonthPivot

		--------------------------------------------------------------------
		-- Assemble all the data to display the result set for report
		--------------------------------------------------------------------

		select tbl1.Account , 
			   isnull(tbl1.[Jan] , 0) as 'JanMinutes', isnull(tbl2.[Jan] , 0) as 'JanRevenue', 
			   isnull(tbl1.[Feb] , 0) as 'FebMinutes', isnull(tbl2.[Feb] , 0) as 'FebRevenue',
			   isnull(tbl1.[Mar] , 0) as 'MarMinutes', isnull(tbl2.[Mar] , 0) as 'MarRevenue',  
			   isnull(tbl1.[Apr] , 0) as 'AprMinutes', isnull(tbl2.[Apr] , 0) as 'AprRevenue',
			   isnull(tbl1.[May] , 0) as 'MayMinutes', isnull(tbl2.[May] , 0) as 'MayRevenue', 
			   isnull(tbl1.[Jun] , 0) as 'JunMinutes', isnull(tbl2.[Jun] , 0) as 'JunRevenue', 
			   isnull(tbl1.[Jul] , 0) as 'JulMinutes', isnull(tbl2.[Jul] , 0) as 'JulRevenue', 
			   isnull(tbl1.[Aug] , 0) as 'AugMinutes', isnull(tbl2.[Aug] , 0) as 'AugRevenue',
			   isnull(tbl1.[Sep] , 0) as 'SepMinutes', isnull(tbl2.[Sep] , 0) as 'SepRevenue', 
			   isnull(tbl1.[Oct] , 0) as 'OctMinutes', isnull(tbl2.[Oct] , 0) as 'OctRevenue',  
			   isnull(tbl1.[Nov] , 0) as 'NovMinutes', isnull(tbl2.[Nov] , 0) as 'NovRevenue',
			   isnull(tbl1.[Dec] , 0) as 'DecMinutes', isnull(tbl2.[Dec] , 0) as 'DecRevenue'
		from #TempTotalMinutesByMonthPivot tbl1
		inner join #TempTotalAmountByMonthPivot tbl2 on tbl1.AccountID = tbl2.AccountID
		order by tbl1.Account

	--	----------------------------------------------------------------------
	--	-- Calculate TOTAL of the above result set to display in the Report
	--	----------------------------------------------------------------------

	select @TotalResult = 
			   'TOTAL' + '|' + 
		       convert(varchar(100) ,sum(isnull(tbl1.[Jan] , 0))) + '|' + 
			   convert(varchar(100) ,sum(isnull(tbl2.[Jan] , 0))) + '|' + 
			   convert(varchar(100) ,sum(isnull(tbl1.[Feb] , 0))) + '|' +
			   convert(varchar(100) ,sum(isnull(tbl2.[Feb] , 0))) + '|' +
			   convert(varchar(100) ,sum(isnull(tbl1.[Mar] , 0))) + '|' + 
			   convert(varchar(100) ,sum(isnull(tbl2.[Mar] , 0))) + '|' +
			   convert(varchar(100) ,sum(isnull(tbl1.[Apr] , 0))) + '|' +
			   convert(varchar(100) ,sum(isnull(tbl2.[Apr] , 0))) + '|' + 
			   convert(varchar(100) ,sum(isnull(tbl1.[May] , 0))) + '|' +
			   convert(varchar(100) ,sum(isnull(tbl2.[May] , 0))) + '|' +
			   convert(varchar(100) ,sum(isnull(tbl1.[Jun] , 0))) + '|' + 
			   convert(varchar(100) ,sum(isnull(tbl2.[Jun] , 0))) + '|' +
			   convert(varchar(100) ,sum(isnull(tbl1.[Jul] , 0))) + '|' + 
			   convert(varchar(100) ,sum(isnull(tbl2.[Jul] , 0))) + '|' +  
			   convert(varchar(100) ,sum(isnull(tbl1.[Aug] , 0))) + '|' +
			   convert(varchar(100) ,sum(isnull(tbl2.[Aug] , 0))) + '|' +
			   convert(varchar(100) ,sum(isnull(tbl1.[Sep] , 0))) + '|' + 
			   convert(varchar(100) ,sum(isnull(tbl2.[Sep] , 0))) + '|' +
			   convert(varchar(100) ,sum(isnull(tbl1.[Oct] , 0))) + '|' + 
			   convert(varchar(100) ,sum(isnull(tbl2.[Oct] , 0))) + '|' + 
			   convert(varchar(100) ,sum(isnull(tbl1.[Nov] , 0))) + '|' +
			   convert(varchar(100) ,sum(isnull(tbl2.[Nov] , 0))) + '|' + 
			   convert(varchar(100) ,sum(isnull(tbl1.[Dec] , 0))) + '|' +
			   convert(varchar(100) ,sum(isnull(tbl2.[Dec] , 0))) 
		from #TempTotalMinutesByMonthPivot tbl1
		inner join #TempTotalAmountByMonthPivot tbl2 on tbl1.AccountID = tbl2.AccountID

		if ( @TotalResult is NULL )
		Begin

					select @TotalResult = 
							   'TOTAL' + '|'  +
							   '0.00' + '|' + '0.00' + '|' + '0.00' + '|' +
							   '0.00' + '|' + '0.00' + '|' + '0.00' + '|' +
							   '0.00' + '|' + '0.00' + '|' + '0.00' + '|' +
							   '0.00' + '|' + '0.00' + '|' + '0.00' + '|' +
							   '0.00' + '|' + '0.00' + '|' + '0.00' + '|' +
							   '0.00' + '|' + '0.00' + '|' + '0.00' + '|' +
							   '0.00' + '|' + '0.00' + '|' + '0.00' + '|' +
							   '0.00' + '|' + '0.00' + '|' + '0.00' + '|' 

		End




End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!! While extracting Monthly Termination Report (Traffic & Revenue). '+ ERROR_MESSAGE()
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

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempTotalMinutesByMonth') )
		Drop table #TempTotalMinutesByMonth

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempTotalMinutesByMonthPivot') )
		Drop table #TempTotalMinutesByMonthPivot

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempTotalAmountByMonth') )
		Drop table #TempTotalAmountByMonth

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempTotalAmountByMonthPivot') )
		Drop table #TempTotalAmountByMonthPivot

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempExchangeRate') )
		Drop table #tempExchangeRate
GO
