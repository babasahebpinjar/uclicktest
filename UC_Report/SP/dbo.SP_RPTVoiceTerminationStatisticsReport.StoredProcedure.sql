USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_RPTVoiceTerminationStatisticsReport]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_RPTVoiceTerminationStatisticsReport]
(
     @ReportID int,
	 @StartDate datetime,
	 @EndDate datetime,  
	 @CallTypeID int,
	 @AccountIDList nvarchar(max), 
	 @CountryIDList nvarchar(max),
	 @DestinationIDList nvarchar(max),
 	 @ServiceLevelIDList nvarchar(max),
     @SummarizeByFlag int , -- 1 for Account , 2 for Country and 3 for Routing Destination
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

----------------------------------------------------------------
-- Check the value of summarize by Flag to ensure that the valid
-- values are passed
----------------------------------------------------------------

if ( isnull(@SummarizeByFlag , -9999) not in (1,2,3) )
Begin

		set @ErrorDescription = 'ERROR !!! Value of DSummarize By Flag is NULL or not valid. Correct values are 1/2/3'
		set @ResultFlag = 1
		GOTO ENDPROCESS

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
				  GOTO PROCESSCOUNTRY
				  
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


    	---------------------------------------------------------------------
		-- Select the subset of data on which report needs to be run based on
		-- Call Date
		---------------------------------------------------------------------

		select summ.AccountID, isnull(acc.Account , '******') as Account,
			convert(Decimal(19,2) ,summ.CallDuration/60.0) as CallDuration, 
			convert(decimal(19,2) ,summ.ChargeDuration) as ChargeDuration,
			summ.RoutingDestinationID , isnull(rdest.Destination , '*****') as RoutingDestination,
			isnull(cou.CountryID, -1) as CountryID , isnull(cou.Country , '*****') as Country,
			summ.INServiceLevelID , isnull(insl.ServiceLevel , '*****') as INServiceLevel
		into #TempDailyINUnionOutFinancial
		from tb_DailyINUnionOutFinancial summ
		left join REFERENCESERVER.UC_REference.dbo.tb_Calltype ct on summ.CalltypeID = ct.CallTypeID
		left join REFERENCESERVER.UC_REference.dbo.tb_Account acc on summ.AccountID = acc.AccountID
		left join REFERENCESERVER.UC_REference.dbo.tb_Destination rdest on summ.RoutingDestinationID = rdest.DestinationID
		left join REFERENCESERVER.UC_REference.dbo.tb_Country cou on rdest.CountryID = cou.CountryID
		left join REFERENCESERVER.UC_REference.dbo.tb_ServiceLevel insl on summ.INServiceLevelID = insl.ServiceLevelID
		where CallDate between @StartDate and @EndDate
		and summ.CalltypeID = isnull(@CallTypeID , summ.CallTypeID)
		and summ.DirectionID = 2

		--select *
		--from #TempDailyINUnionOutFinancial

		-----------------------------------------------------
		-- Extract the result set for the input parameters
		-----------------------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempFinalResult') )
				Drop table #tempFinalResult

		Create table #tempFinalResult
		(
			ID int,
			Name varchar(200),
			OriginalMinutes Decimal(19,2),
			ChargeMinutes Decimal(19,2)
		)

		set @SQLStr1 = 'Select ' + 
		                      Case
									When @SummarizeByFlag = 1 then 'tbl1.AccountID , tbl1.Account,'
									When @SummarizeByFlag = 2 then 'tbl1.CountryID , tbl1.Country ,'
									When @SummarizeByFlag = 3 then 'tbl1.RoutingDestinationID , tbl1.RoutingDestination,'
							  End + char(10) +
						'convert(Decimal(19,2),sum(CallDuration)),' +  char(10) +
						'convert(Decimal(19,2),sum(ChargeDuration))'

         --print @SQLStr1

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
						End 
 
        --print  @SQLStr2

		set @SQLStr3 = 'Group by ' + 
						Case

							When @SummarizeByFlag = 1 then ' tbl1.AccountID , tbl1.Account'
							When @SummarizeByFlag = 2 then ' tbl1.CountryID , tbl1.Country'
							When @SummarizeByFlag = 3 then ' tbl1.RoutingDestinationID , tbl1.RoutingDestination'

						End 

        --print @SQLStr3

        set @SQLStr = @SQLStr1 + @SQLStr2 + @SQLStr3

		--print @SQLStr

		insert into #tempFinalResult
		Exec (@SQLStr)

		-------------------------------------------------------------------
		-- Extract the TOTAL for the result set to be displayed in Report
		-------------------------------------------------------------------

		Declare @TotalOriginalMinutes Decimal(19,2),
		        @TotalChargeMinutes Decimal(19,2)


        select @TotalOriginalMinutes = convert(decimal(19,2),sum(OriginalMinutes)),
		       @TotalChargeMinutes = convert(decimal(19,2) ,sum(ChargeMinutes))
        from #tempFinalResult   

		--------------------------------------------------------------
		-- Display the final result set with Percentage Distribution
		--------------------------------------------------------------

		Select Name , OriginalMinutes , ChargeMinutes,
		       convert(decimal(19,2) ,(OriginalMinutes*100)/@TotalOriginalMinutes) as 'Percentage'
		from #tempFinalResult
		Order by OriginalMinutes Desc

		set @TotalResult = 'TOTAL' + '|' + convert(varchar(100),@TotalOriginalMinutes) + '|' + convert(varchar(100),@TotalChargeMinutes)


End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!! While extracting Voice Termination Statistics Report. '+ ERROR_MESSAGE()
		set @ResultFlag = 1
		GOTO ENDPROCESS

End Catch

--Select 'Step 4..' , getdate()

ENDPROCESS:


if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempFinalResult') )
		Drop table #tempFinalResult

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAccountIDTable') )
		Drop table #TempAccountIDTable


if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCountryIDTable') )
		Drop table #TempCountryIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempServiceLevelIDTable') )
		Drop table #TempServiceLevelIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDestinationIDTable') )
		Drop table #TempDestinationIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDailyINUnionOutFinancial') )
		Drop table #TempDailyINUnionOutFinancial
GO
