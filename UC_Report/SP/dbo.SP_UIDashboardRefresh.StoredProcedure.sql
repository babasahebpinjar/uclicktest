USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIDashboardRefresh]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_UIDashboardRefresh]
(
	@DateOffset int,
	@TopN int
)
As

Declare @ErrorMsgStr varchar(200)

---------------------------------------------------
-- REFRESH 1 : Terminating traffic for Last 30 Day
---------------------------------------------------

Begin Try

       Exec SP_UIDashboardTerminatingTraffic @DateOffset
		
End Try

Begin Catch

		set @ErrorMsgStr = 'ERROR !!! While refreshng Terminating Traffic Chart. ' + ERROR_MESSAGE()
		RaisError('%s' , 16 , 1 , @ErrorMsgStr)
		Return 1

End Catch

-----------------------------------------------------------
-- REFRESH 2 : Financial Revenue Vs Cost for Current month
-----------------------------------------------------------

Begin Try

       Exec SP_UIDashboardFinancial
		
End Try

Begin Catch

		set @ErrorMsgStr = 'ERROR !!! While refreshng Revenue Vs Cost Chart. ' + ERROR_MESSAGE()
		RaisError('%s' , 16 , 1 , @ErrorMsgStr)
		Return 1

End Catch

----------------------------------------------------------
-- REFRESH 3 : Top 10 Terminating Revenue By Carrier Code
-- for Last 30 Days
----------------------------------------------------------

Begin Try

       Exec SP_UIDashboardTerminatingRevenueByCarrierCode @DateOffset, @TopN
		
End Try

Begin Catch

		set @ErrorMsgStr = 'ERROR !!! While refreshng Terminating Revenue Dashboard. ' + ERROR_MESSAGE()
		RaisError('%s' , 16 , 1 , @ErrorMsgStr)
		Return 1

End Catch

----------------------------------------------------------
-- REFRESH 4 : Top 10 Originating Cost By Carrier Code
-- and Country for Last 30 Days
----------------------------------------------------------

Begin Try

       Exec SP_UIDashboardOrigCostByCarrierCodeAndCountry @DateOffset, @TopN
		
End Try

Begin Catch

		set @ErrorMsgStr = 'ERROR !!! While refreshng Originating Cost Dashboard. ' + ERROR_MESSAGE()
		RaisError('%s' , 16 , 1 , @ErrorMsgStr)
		Return 1

End Catch

----------------------------------------------------------
-- REFRESH 5 : Daily Hourly QOS Dashboard
----------------------------------------------------------

Begin Try

       Exec SP_UIDashboardHourlyQOS
		
End Try

Begin Catch

		set @ErrorMsgStr = 'ERROR !!! While refreshng Daily Hourly QOS Charts. ' + ERROR_MESSAGE()
		RaisError('%s' , 16 , 1 , @ErrorMsgStr)
		Return 1

End Catch

----------------------------------------------------------
-- REFRESH 6 : Current Month CDR Error Summary Dashboard
----------------------------------------------------------

Begin Try

       Exec SP_UIDashboardCDRErrorSummary
		
End Try

Begin Catch

		set @ErrorMsgStr = 'ERROR !!! While refreshng CDR Error Summary Dashboard. ' + ERROR_MESSAGE()
		RaisError('%s' , 16 , 1 , @ErrorMsgStr)
		Return 1

End Catch


----------------------------------------------------------
-- REFRESH 7 : Last 6 months Traffic and Margin Analysis
----------------------------------------------------------

Begin Try

       Exec SP_UIDashboardTrafficAndMarginAnalysis
		
End Try

Begin Catch

		set @ErrorMsgStr = 'ERROR !!! While refreshng Traffic and Margin Analysis Chart. ' + ERROR_MESSAGE()
		RaisError('%s' , 16 , 1 , @ErrorMsgStr)
		Return 1

End Catch
GO
