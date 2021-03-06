USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSPrepaidSummarizeAndMartRefresh]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_BSPrepaidSummarizeAndMartRefresh]
(
	@SelectDate datetime,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int output
)
As

-----------------------------------------------------------------------------
-- Check if there are any prepaid accounts for the period of the select date
------------------------------------------------------------------------------
Declare @PrepaidPeriod int
set @PrepaidPeriod = convert(int ,replace(convert(varchar(7) , @SelectDate , 120),'-' , ''))

--select @PrepaidPeriod

if not exists ( select 1 from ReferenceServer.UC_Reference.dbo.tb_AccountMode where Period = @PrepaidPeriod and AccountModeTypeID = -2)
	GOTO ENDPROCESS -- Exit as we dont need to calculate the prepaid balance for any account

------------------------------------------------------
-- STEP 1: Get all the data from FTR Summary tables on
-- each CDR database to the Report Server
------------------------------------------------------

----------------------------------------------------------------
-- Create the temporary table to store all the collected data
-- from the summarized CDR databases for the call date
-----------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempPrepaidFTRSummary') )
		Drop table #tempPrepaidFTRSummary

Create Table #tempPrepaidFTRSummary
(
   CallDate datetime,
   AccountID int,
   Amount Decimal(19,6),
   CurrencyID int
)

Begin Try

			set @ErrorDescription = NULL
			set @ResultFlag = 0

			Exec SP_BSPrepaidCollectTrafficFromCDRDatabases  @SelectDate , @ErrorDescription Output , @ResultFlag Output

			if ( @ResultFlag = 1 )
			Begin

			       set @ErrorDescription = 'ERROR !!!! During Collection of Summarized Data from CDR Databases. ' + @ErrorDescription
				   GOTO ENDPROCESS	

			End

End Try

Begin Catch

			set @ErrorDescription = 'ERROR !!!! During Collection of Summarized Data from CDR Databases. ' + ERROR_MESSAGE()
			set @ResultFlag = 1
			GOTO ENDPROCESS

End Catch


------------------------------------------------------
-- STEP 2: Populate Prepaid Balance Mart
------------------------------------------------------

if ( (select count(*) from #tempPrepaidFTRSummary) = 0 ) -- No Prepaid Traffic for this date
	GOTO ENDPROCESS

Else
Begin

		-------------------------------------------------------------------------------------------
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

		-------------------------------------------------------------
		-- Delete data for the calldate from the Prepaid balance mart
		-------------------------------------------------------------
		Delete from tb_PrepaidCurrentBalance
		Where CallDate = @SelectDate

		--------------------------------------------------------------
		-- Insert newly calculated data into the Prepaid Balance Mart
		--------------------------------------------------------------
		insert into tb_PrepaidCurrentBalance
		(
			AccountID,
			CallDate,
			Amount,
			ModifiedByID,
			ModifiedDate
		)
		Select AccountID , CallDate , 
		       convert(decimal(19,2),sum(Amount/tbl2.ExchangeRate)) , -1, getdate()
		from #tempPrepaidFTRSummary tbl1
		inner join #tempExchangeRate tbl2 on tbl1.CurrencyID = tbl2.CurrencyID
									and tbl1.CallDate between tbl2.BeginDate and isnull(tbl2.EndDate ,tbl1.CallDate) 
		group by AccountID , CallDate

End

ENDPROCESS:
------------------------------------------------------------
-- Drop all the temporary tables post processing activity
------------------------------------------------------------

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempPrepaidFTRSummary') )
		Drop table #tempPrepaidFTRSummary

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempExchangeRate') )
		Drop table #tempExchangeRate

Return 0
GO
