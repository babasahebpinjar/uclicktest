USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_RPTMonthlyOriginationMinutesReport]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_RPTMonthlyOriginationMinutesReport]
(
     @ReportID int,
	 @RunYear int,  
	 @CallTypeID int,
	 @AccountIDList nvarchar(max), 
	 @CommercialTrunkIDList nvarchar(max),
	 @ServiceLevelIDList nvarchar(max),
	 @TotalResult nvarchar(max) Output,
 	 @ErrorDescription varchar(2000) Output,
	 @ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @AllAccountFlag int = 0,
		@AllCommercialTrunkFlag int = 0,
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

-------------------------------------------------------------
-- Set the CALL TYPE to NULL in case the value passed is 0
-- indicating that all CALL TYPES need to be considered
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
				  GOTO PROCESSSERVICELEVEL
				  
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

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDailyINUnionOutFinancial') )
				Drop table #TempDailyINUnionOutFinancial


        Create table #TempDailyINUnionOutFinancial
		(
			Account varchar(100),
			BillingCode varchar(60),
			CallMonth varchar(20),
            Minutes Decimal(19,2)
		)
        ------------------------------------------------------------------------
		-- Select the data based on the input criteria from the financial tables
		------------------------------------------------------------------------

		set @SQLStr =
		'select acc.Account , ctrnk.Trunk as BillingCode , ' + char(10) + 
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
		'	   End CallMonth, ' + char(10) + 
		'		sum(convert(Decimal(19,2) ,CallDuration/60.0)) as Minutes' + char(10) + 
		'from tb_DailyINUnionOutFinancial summ' + char(10) + 
		'left join REFERENCESERVER.UC_REference.dbo.tb_Account acc on summ.AccountID = acc.AccountID' + char(10) +
		'left join REFERENCESERVER.UC_REference.dbo.tb_Trunk ctrnk on summ.CommercialTrunkID = ctrnk.TrunkID' + char(10) +
		'inner join #TempServiceLevelIDTable sltb on summ.INServiceLevelID  = sltb.ServiceLevelID' + char(10) +
		Case
			When @AllAccountFlag = 1 then ''
			Else ' inner join #TempAccountIDTable AccList on summ.AccountID = AccList.AccountID ' + char(10)
		End + 
		Case
			When  @AllCommercialTrunkFlag  = 1 then ''
			Else ' inner join #TempCommercialTrunkIDTable CommList on summ.CommercialTrunkID = CommList.CommercialTrunkID ' + char(10)
		End +
		'where directionID = 2' + char(10) +
		'and year(CallDate) =  ' + Convert(varchar(4) ,@RunYear) + char(10) +
		'and CalltypeID = ' + char(10) +
		Case
				when @CallTypeID is NULL then ' summ.CallTypeID ' + char(10)
				else Convert(varchar(20) ,@CallTypeID) +  char(10) 
		End +			
		'group by acc.Account , ctrnk.Trunk , ' + char(10) +
		'		 Case ' + char(10) +
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
		'	   End '

		insert into #TempDailyINUnionOutFinancial
		Exec (@SQLStr)
		
		-----------------------------------------------------------------------------
		-- Pivot the extracted data based on the Call Date to create the final data
		-- set
		-----------------------------------------------------------------------------

	    Select *
		into #TempFinalResultSet
		from
		(
				SELECT   Account, BillingCode , [Jan] , [Feb] , [Mar] , [Apr] , [May] , [Jun] , [Jul],
						 [Aug] , [Sep] , [Oct] , [Nov] , [Dec] 
				FROM  #TempDailyINUnionOutFinancial
				PIVOT
				(
					   SUM(Minutes) 
					   FOR CallMonth IN 
					   (
						 [Jan] , [Feb] , [Mar] , [Apr] , [May] , [Jun] ,
						 [Jul] , [Aug] , [Sep] , [Oct] , [Nov] , [Dec]
					   )
				) AS PivotTable
		) as TBL1

		--------------------------------------------
		-- Display the result set for the report
		--------------------------------------------

		SELECT  Account, BillingCode , isnull([Jan], 0.00) as [Jan], 
		        isnull([Feb], 0.00) as [Feb] , isnull([Mar], 0.00) as [Mar] , 
				isnull([Apr], 0.00) as [Apr] , isnull([May], 0.00) as [May] ,
				isnull([Jun], 0.00) as [Jun] , isnull([Jul], 0.00) as [Jul] ,
				isnull([Aug], 0.00) as [Aug] , isnull([Sep], 0.00) as [Sep] , 
				isnull([Oct], 0.00) as [Oct] , isnull([Nov], 0.00) as [Nov] , 
				isnull([Dec], 0.00) as [Dec]
		FROM  #TempFinalResultSet

		---------------------------------------------------
		-- Display the Total for the selected Result set
		---------------------------------------------------

		if ((select count(*) from #TempFinalResultSet ) = 0 ) 
		Begin
				set @TotalResult = 'TOTAL' + '|' +  '' + '|' +
				'0.00' + '|' + '0.00' + '|' +
				'0.00' + '|' + '0.00' + '|' +
				'0.00' + '|' + '0.00' + '|' +
				'0.00' + '|' + '0.00' + '|' + 
				'0.00' + '|' + '0.00' + '|' +
				'0.00' + '|' + '0.00'


		End

		Else
		Begin

				select @TotalResult = 
						'TOTAL' + '|' +  '' + '|' + 
						convert(varchar(100) ,sum(isnull([Jan], 0.00))) + '|' +
						convert(varchar(100) ,sum(isnull([Feb], 0.00))) + '|' +
						convert(varchar(100) ,sum(isnull([Mar], 0.00))) + '|' +
						convert(varchar(100) ,sum(isnull([Apr], 0.00))) + '|' +
						convert(varchar(100) ,sum(isnull([May], 0.00))) + '|' + 
						convert(varchar(100) ,sum(isnull([Jun], 0.00))) + '|' +
						convert(varchar(100) ,sum(isnull([Jul], 0.00))) + '|' + 
						convert(varchar(100) ,sum(isnull([Aug], 0.00))) + '|' + 
						convert(varchar(100) ,sum(isnull([Sep], 0.00))) + '|' + 
						convert(varchar(100) ,sum(isnull([Oct], 0.00))) + '|' +
						convert(varchar(100) ,sum(isnull([Nov], 0.00))) + '|' + 
						convert(varchar(100) ,sum(isnull([Dec], 0.00)))
				from #TempFinalResultSet

		End
		
End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!! While extracting Monthly Originating Minutes Report. '+ ERROR_MESSAGE()
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

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempFinalResultSet') )
		Drop table #TempFinalResultSet
GO
