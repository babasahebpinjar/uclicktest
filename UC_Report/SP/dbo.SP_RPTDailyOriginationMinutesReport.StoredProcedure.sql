USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_RPTDailyOriginationMinutesReport]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_RPTDailyOriginationMinutesReport]
(
     @ReportID int,
	 @RunMonth int,
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
			CallDate varchar(20),
            Minutes Decimal(19,2)
		)

        ------------------------------------------------------------------------
		-- Select the data based on the input criteria from the financial tables
		------------------------------------------------------------------------

		set @SQLStr =
		'select acc.Account , ctrnk.Trunk , ' + char(10) + 
		'substring(convert(varchar(10) ,CallDate , 120) , 9,2) ,' + char(10) +
		'sum(convert(Decimal(19,2) ,CallDuration/60.0))' + char(10) + 
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
		'and month(CallDate) =  ' + Convert(varchar(4),@RunMonth) + char(10) +
		'and year(CallDate) =  ' + Convert(varchar(4),@RunYear) + char(10) +
		'and CalltypeID = ' + char(10) +
		Case
				when @CallTypeID is NULL then ' summ.CallTypeID ' + char(10)
				else Convert(varchar(20) ,@CallTypeID) +  char(10) 
		End +			
		'group by acc.Account , ctrnk.Trunk , ' + char(10) +
		'substring(convert(varchar(10) ,CallDate , 120) , 9,2)'


		insert into #TempDailyINUnionOutFinancial
		Exec (@SQLStr)

		-----------------------------------------------------------------------------
		-- Pivot the extracted data based on the Call Date to create the final data
		-- set
		-----------------------------------------------------------------------------
		
		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempFinalQueryResult') )
				Drop table #tempFinalQueryResult

		select *
		into #tempFinalQueryResult
		From
		(
				SELECT   Account, BillingCode , [01] , [02] , [03] , [04] , [05] , [06] , [07],
						 [08] , [09] , [10] , [11] , [12] , [13] , [14] , [15] , [16] , [17] , [18],
						 [19] , [20] , [21] , [22] , [23] , [24] , [25] , [26] , [27] , [28], [29],
						 [30] , [31]
				FROM  #TempDailyINUnionOutFinancial
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
		) as TBL1

		-----------------------------------------
		-- Display the results for the report
		-----------------------------------------

		if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempFinalQueryResult2') )
				Drop table #tempFinalQueryResult2

		select Account , BillingCode,
				sum (
						isnull(tbl2.[01] , 0) + isnull(tbl2.[02] , 0) + isnull(tbl2.[03] , 0) + 
						isnull(tbl2.[04] , 0) + isnull(tbl2.[05] , 0) + isnull(tbl2.[06] , 0) + 
						isnull(tbl2.[07] , 0) + isnull(tbl2.[08] , 0) + isnull(tbl2.[09] , 0) + 
						isnull(tbl2.[10] , 0) + isnull(tbl2.[11] , 0) + isnull(tbl2.[12] , 0) + 
						isnull(tbl2.[13] , 0) + isnull(tbl2.[14] , 0) + isnull(tbl2.[15] , 0) + 
						isnull(tbl2.[16] , 0) + isnull(tbl2.[17] , 0) + isnull(tbl2.[18] , 0) + 
						isnull(tbl2.[19] , 0) + isnull(tbl2.[20] , 0) + isnull(tbl2.[21] , 0) +
						isnull(tbl2.[22] , 0) + isnull(tbl2.[23] , 0) + isnull(tbl2.[24] , 0) +
						isnull(tbl2.[25] , 0) + isnull(tbl2.[26] , 0) + isnull(tbl2.[27] , 0) +
						isnull(tbl2.[28] , 0) + isnull(tbl2.[29] , 0) + isnull(tbl2.[30] , 0) +
						isnull(tbl2.[31] , 0)
					) as TotalMonth,
			   isnull(tbl2.[01] , 0) as '01', isnull(tbl2.[02] , 0) as '02',  isnull(tbl2.[03] , 0) as '03',
			   isnull(tbl2.[04] , 0) as '04', isnull(tbl2.[05] , 0) as '05',  isnull(tbl2.[06] , 0) as '06',
			   isnull(tbl2.[07] , 0) as '07', isnull(tbl2.[08] , 0) as '08',  isnull(tbl2.[09] , 0) as '09',
			   isnull(tbl2.[10] , 0) as '10', isnull(tbl2.[11] , 0) as '11',  isnull(tbl2.[12] , 0) as '12',
			   isnull(tbl2.[13] , 0) as '13', isnull(tbl2.[14] , 0) as '14',  isnull(tbl2.[15] , 0) as '15',
			   isnull(tbl2.[16] , 0) as '16', isnull(tbl2.[17] , 0) as '17',  isnull(tbl2.[18] , 0) as '18',
			   isnull(tbl2.[19] , 0) as '19', isnull(tbl2.[20] , 0) as '20',  isnull(tbl2.[21] , 0) as '21',
			   isnull(tbl2.[22] , 0) as '22', isnull(tbl2.[23] , 0) as '23',  isnull(tbl2.[24] , 0) as '24',
			   isnull(tbl2.[25] , 0) as '25', isnull(tbl2.[26] , 0) as '26',  isnull(tbl2.[27] , 0) as '27',
			   isnull(tbl2.[28] , 0) as '28', isnull(tbl2.[29] , 0) as '29',  isnull(tbl2.[30] , 0) as '30',
			   isnull(tbl2.[31] , 0) as '31'
        into #tempFinalQueryResult2
		from #tempFinalQueryResult tbl2
		group by Account , BillingCode,
				isnull(tbl2.[01] , 0) , isnull(tbl2.[02] , 0) ,  isnull(tbl2.[03] , 0) ,
				isnull(tbl2.[04] , 0) , isnull(tbl2.[05] , 0) ,  isnull(tbl2.[06] , 0) ,
				isnull(tbl2.[07] , 0) , isnull(tbl2.[08] , 0) ,  isnull(tbl2.[09] , 0) ,
				isnull(tbl2.[10] , 0) , isnull(tbl2.[11] , 0) ,  isnull(tbl2.[12] , 0) ,
				isnull(tbl2.[13] , 0) , isnull(tbl2.[14] , 0) ,  isnull(tbl2.[15] , 0) ,
				isnull(tbl2.[16] , 0) , isnull(tbl2.[17] , 0) ,  isnull(tbl2.[18] , 0) ,
				isnull(tbl2.[19] , 0) , isnull(tbl2.[20] , 0) ,  isnull(tbl2.[21] , 0) ,
				isnull(tbl2.[22] , 0) , isnull(tbl2.[23] , 0) ,  isnull(tbl2.[24] , 0) ,
				isnull(tbl2.[25] , 0) , isnull(tbl2.[26] , 0) ,  isnull(tbl2.[27] , 0) ,
				isnull(tbl2.[28] , 0) , isnull(tbl2.[29] , 0) ,  isnull(tbl2.[30] , 0) ,
				isnull(tbl2.[31] , 0) 


		select Account , BillingCode, TotalMonth,
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
		from #tempFinalQueryResult2 tbl2
		order by tbl2.Account

		------------------------------------------------------
		-- Display the TOTAL of the result set for the Report
		------------------------------------------------------

		select @TotalResult = 
			   'TOTAL' + '|' + 
		       '' + '|' +
			   convert(varchar(100) ,sum (isnull(TotalMonth, 0))) + '|' +
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
		from #tempFinalQueryResult2 tbl2

		if ( @TotalResult is NULL )
		Begin

				select @TotalResult = 
						   'TOTAL' + '|' + '' + '|' +
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

		set @ErrorDescription = 'ERROR !!! While extracting Daily Originating Minutes Report. '+ ERROR_MESSAGE()
		set @ResultFlag = 1
		GOTO ENDPROCESS

End Catch

--Select 'Step 4..' , getdate()

ENDPROCESS:


if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempFinalQueryResult') )
		Drop table #tempFinalQueryResult

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempFinalQueryResult2') )
		Drop table #tempFinalQueryResult2

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAccountIDTable') )
		Drop table #TempAccountIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempCommercialTrunkIDTable') )
		Drop table #TempCommercialTrunkIDTable

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempDailyINUnionOutFinancial') )
		Drop table #TempDailyINUnionOutFinancial
GO
