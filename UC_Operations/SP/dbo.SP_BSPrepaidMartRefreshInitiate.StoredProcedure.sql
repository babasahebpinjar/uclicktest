USE [UC_Operations]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSPrepaidMartRefreshInitiate]    Script Date: 5/2/2020 6:25:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_BSPrepaidMartRefreshInitiate]
(
	@LoadBalanceOffset int,
	@RangeValue int,
	@UserID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As 

--Declare @LoadBalanceOffset int = 4,
--	    @RangeValue int = 0,
--		@UserID int = -1,
--		@ErrorDescription varchar(2000),
--		@ResultFlag int

set @ErrorDescription = NULL
set @ResultFlag = 0

----------------------------------------------------------------------------
-- The Prepaid mart refresh has to happen for Current and Current -1 Period
----------------------------------------------------------------------------

Declare @CurrPeriod int 
Declare @CurrRunDate date =  dateadd(mm , -1 ,convert(date ,substring(convert(varchar(10) , getdate(),120) , 1,7) + '-' + '01'))

set @CurrPeriod = convert(int,replace(convert(varchar(7) , @CurrRunDate , 120), '-' , ''))

--------------------------------------------------------------------------------
-- In case the date has changed to 1st of a month, then we need to ensure that
-- traffic for current -2 month is moved into Past Balance, as current period
-- has changed
--------------------------------------------------------------------------------

if (day(getdate()) = 1) -- 1st day of the month
Begin

		----------------------------------------------------------------------------
		-- Call the procedure to calculate the past balance for the prepaid accounts
		----------------------------------------------------------------------------

		Exec ReportServer.UC_Report.dbo.SP_BSCalculatePrepaidPastPeriodBalance


		--------------------------------------------------------------
		-- Delete data for all the months previous to Current -1 from
		-- Current Balance schema
		--------------------------------------------------------------

		Delete from ReportServer.UC_Report.dbo.tb_PrepaidCurrentBalance
		where convert(int ,replace(convert(varchar(7) , getdate(), 120), '-' , '')) < @CurrPeriod

End


----------------------------------------------------------------------
-- Open a cursor to get all the Call Dates for which balance needs to
-- be refreshed based on the CDR files that have been processed
----------------------------------------------------------------------

Declare @VarSelectDate date,
        @VarLastRefreshDate datetime,
		@VarInsertRecFlag int

Declare Prepaid_Refresh_Cur Cursor For
select tbl1.CallDate , tbl1.LastFileUploadDate ,
       Case
			When tbl2.LastRefreshDate is NULL then 1
			Else 0
	   End as InsertRecFlag
from 
(
	select CallDate , max(ModifiedDate) as LastFileUploadDate
	from tb_KPIRefreshInstance
	where convert(int ,
				  convert(varchar(4) ,year(CallDate) ) + right('0' + convert(varchar(2) , month(CallDate)) , 2)
				 ) >= @CurrPeriod
	and Day(CallDate) % @LoadBalanceOffset = @RangeValue
	Group By CallDate
) tbl1
left join tb_PrepaidLastRefreshForCallDate tbl2 on tbl1.CallDate = tbl2.CallDate
where tbl1.LastFileUploadDate > tbl2.LastRefreshDate
or tbl2.LastRefreshDate is NULL

Open Prepaid_Refresh_Cur
Fetch Next From Prepaid_Refresh_Cur
Into @VarSelectDate , @VarLastRefreshDate , @VarInsertRecFlag


While @@FETCH_STATUS = 0
Begin

    Begin Try

				set @ErrorDescription = NULL
				set @ResultFlag = 1

				Exec ReportServer.UC_Report.dbo.SP_BSPrepaidSummarizeAndMartRefresh @VarSelectDate , @ErrorDescription Output , @ResultFlag Output

				if (@ResultFlag = 1)
				Begin 

								set @ErrorDescription = 'ERROR !!! While running Prepaid summarization and mart refresh for date : ' + convert(varchar(10),@VarSelectDate, 120) + '. ' + @ErrorDescription
								set @ResultFlag = 1
								RaisError('%s' , 1,16 , @ErrorDescription)

								Close Prepaid_Refresh_Cur
								Deallocate Prepaid_Refresh_Cur

								GOTO ENDPROCESS

				End 

	End Try

	Begin Catch

				set @ErrorDescription = 'ERROR !!! While running Prepaid summarization and mart refresh for date : ' + convert(varchar(10),@VarSelectDate, 120) + '. ' + ERROR_MESSAGE()
				set @ResultFlag = 1
				RaisError('%s' , 1,16 , @ErrorDescription)

				Close Prepaid_Refresh_Cur
				Deallocate Prepaid_Refresh_Cur

				GOTO ENDPROCESS

	End Catch

	------------------------------------------------------------------------
	-- Update or insert record in the Prepaid Data Refresh for Call Date
	------------------------------------------------------------------------

	if (@VarInsertRecFlag = 1)
	Begin

			insert into tb_PrepaidLastRefreshForCallDate
			(
				CallDate,
				LastRefreshDate,
				ModifiedDate,
				ModifiedByID
			)
			Values
			(
				@VarSelectDate,
				@VarLastRefreshDate,
				getdate(),
				@UserID
			)

	End

	Else
	Begin

			update tb_PrepaidLastRefreshForCallDate
			set LastRefreshDate = @VarLastRefreshDate,
				ModifiedDate = getdate(),
				ModifiedByID = @UserID
			where CallDate = @VarSelectDate


	End


	Fetch Next From Prepaid_Refresh_Cur
	Into @VarSelectDate , @VarLastRefreshDate , @VarInsertRecFlag

End

Close Prepaid_Refresh_Cur
Deallocate Prepaid_Refresh_Cur

ENDPROCESS:

return 0
GO
