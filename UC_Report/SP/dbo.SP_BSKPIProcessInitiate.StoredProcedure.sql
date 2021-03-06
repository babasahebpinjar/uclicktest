USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSKPIProcessInitiate]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSKPIProcessInitiate]
(
    @LoadBalanceOffset int,
	@RangeValue int
)
As

Declare   @ErrorDescription varchar(2000) ,
	      @ResultFlag int 

-----------------------------------------------------------------
-- We will perfrom two steps in this procdeure, namely:
-- 1. Assign the KPI Object Instannce ID for all pending refresh
-- 2. Run the KPI Summarize and Mart Refresh for all the qualifying
--    dates
-------------------------------------------------------------------

set @ErrorDescription = NULL
set @ResultFlag = 0

Begin Try

		Exec REFERENCESERVER.UC_Operations.dbo.SP_BSAssignKPRefreshBatch @LoadBalanceOffset , @RangeValue , 
		                                                                 @ErrorDescription Output,
																		 @ResultFlag Output

        if (@ResultFlag = 1)
		Begin

				set @ErrorDescription = 'ERROR !!! During while assigning KPI Refresh ID to pending Instances. ' + @ErrorDescription
				set @ResultFlag = 1
				RaisError('%s' , 1,16 , @ErrorDescription)
				GOTO ENDPROCESS

		End
		 
End Try

Begin Catch

				set @ErrorDescription = 'ERROR !!! During while assigning KPI Refresh ID to pending Instances. ' + ERROR_MESSAGE()
				set @ResultFlag = 1
				RaisError('%s' , 1,16 , @ErrorDescription)
				GOTO ENDPROCESS

End Catch


----------------------------------------------------
-- Check if there are any KPI mart refresh which
-- have failed due to Deadlock. Move them into
-- registered state again, so that the system can
-- initiate the run
----------------------------------------------------

update REFERENCESERVER.UC_Operations.dbo.tb_ObjectInstance
set statusid = 10210,
    modifiedDate = getdate(),
	Remarks = NULL
where Day(convert(date , ObjectInstance))%@LoadBalanceOffset = @RangeValue
and statusID = 10213 -- KPI Failed
and Remarks like '%deadlock%'

-----------------------------------------------------------------------
-- Run the KPI Summarize and Mart Refresh for all the qualifying
-- Object Instances with status as "KPI Registered"
------------------------------------------------------------------------

Declare @VarObjectInstance varchar(60),
        @SelectDate datetime

Declare Process_KPI_ObjectInstance_Cur Cursor For
Select ObjectInstance
from REFERENCESERVER.UC_Operations.dbo.tb_ObjectInstance
where Day(convert(date , ObjectInstance))%@LoadBalanceOffset = @RangeValue
and statusID = 10210 -- KP Registered

Open Process_KPI_ObjectInstance_Cur
Fetch Next From Process_KPI_ObjectInstance_Cur
Into @VarObjectInstance


While @@FETCH_STATUS = 0
Begin

    Begin Try

	            set @SelectDate = convert(date , @VarObjectInstance)

				set @ErrorDescription = NULL
				set @ResultFlag = 1

				Exec SP_BSKPISummarizeAndMartRefresh @SelectDate , @ErrorDescription Output , @ResultFlag Output

				if (@ResultFlag = 1)
				Begin 

								set @ErrorDescription = 'ERROR !!! While running summarization and mart refresh for date : ' + @VarObjectInstance + '. ' + @ErrorDescription
								set @ResultFlag = 1
								RaisError('%s' , 1,16 , @ErrorDescription)

								Close Process_KPI_ObjectInstance_Cur
								Deallocate Process_KPI_ObjectInstance_Cur

								GOTO ENDPROCESS

				End 

	End Try

	Begin Catch

				set @ErrorDescription = 'ERROR !!! While running summarization and mart refresh for date : ' + @VarObjectInstance + '. ' + ERROR_MESSAGE()
				set @ResultFlag = 1
				RaisError('%s' , 1,16 , @ErrorDescription)

				Close Process_KPI_ObjectInstance_Cur
				Deallocate Process_KPI_ObjectInstance_Cur

				GOTO ENDPROCESS

	End Catch


	Fetch Next From Process_KPI_ObjectInstance_Cur
	Into @VarObjectInstance

End

Close Process_KPI_ObjectInstance_Cur
Deallocate Process_KPI_ObjectInstance_Cur


ENDPROCESS:

Return 0
GO
