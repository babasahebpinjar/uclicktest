USE [UC_Operations]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSAssignKPRefreshBatch]    Script Date: 5/2/2020 6:25:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSAssignKPRefreshBatch]
(
    @LoadBalanceOffset int,
	@RangeValue int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0


-----------------------------------------------------------------------
-- Look for entries in the KPI Refresh Instance, which do not have
-- an assigned Refresh Batch
------------------------------------------------------------------------

if not exists ( select 1 from tb_KPIRefreshInstance where KPIRefreshBatchID is NULL )
Begin

		Return 0

End 

------------------------------------------------------------------------------
-- Check to see if among the pending Call dates for KPI refresh, are there any
-- dates qualify for mart refresh for this instance
-------------------------------------------------------------------------------

Else
Begin

		if not exists ( 
		                 select 1 
						 from tb_KPIRefreshInstance  
						 where KPIRefreshBatchID is NULL
						 and Day(CallDate)%@LoadBalanceOffset = @RangeValue
					  )
		Begin

				Return 0

		End

End


Declare @ObjectID int

select @ObjectID = ObjectID
from tb_Object
where ObjectTypeID = 102
and ObjectName = 'Data Mart Refresh'


if (@ObjectID is NULL )
Begin

	set @ErrorDescription = 'ERROR !!!! No Object configured in system for Data Mart Refresh'
	set @ResultFlag = 1
	RaisError('%s' , 1, 16 , @ErrorDescription)
	Return 1

End

----------------------------------------------------------------------
-- For all the distinct Call Dates which has no Refresh Batch assigned
-- loop through
----------------------------------------------------------------------

Declare @VarCallDate Date,
        @KPIRefreshBatchID int

DECLARE db_KPIAssign_Batch_Cur CURSOR FOR  
select CallDate  
from
(
	select Calldate , sum(SuccessRecords + FailedREcords) as TotalRecords,
	       min(ModifiedDate) as MinRecordDate
	from tb_KPIRefreshInstance
	where KPIRefreshBatchID is NULL
	and Day(CallDate)%@LoadBalanceOffset = @RangeValue
	group by Calldate
) tbl1
where TotalRecords > 5000 -- Only proceed when the number of records to refresh is more than a certain count
     or
	  datediff(mi , MinRecordDate , getdate()) >= 15 -- Proceed if for this call date refresh has been pending for more than certain time

OPEN db_KPIAssign_Batch_Cur  
FETCH NEXT FROM db_KPIAssign_Batch_Cur
INTO @VarCallDate

WHILE @@FETCH_STATUS = 0   
BEGIN  
     
	   Begin Try
			   --------------------------------------------------------------------------------------
			   -- Check if the data mart refresh entry exists for the call date or not in the 
			   -- Object instance schema
			   --------------------------------------------------------------------------------------

			   if not exists ( select 1 from tb_ObjectInstance where ObjectID = @ObjectID and ObjectInstance = convert(varchar(10) , @VarCallDate , 120))
			   Begin

						----------------------------------------------------------------------
						-- This is the fist instance of registration for KPI refresh of this
						-- call date. We need to create an entry in the tb_ObjectInstance
						-- table with status set as "KPI Refresh Registered"
						-----------------------------------------------------------------------

						insert into tb_ObjectInstance
						(
							ObjectID,
							ObjectInstance,
							StatusID,
							StartDate,
							EndDate,
							ProcessStartTime,
							ProcessEndTime,
							Remarks,
							ModifiedDate,
							ModifiedByID 
						)
						Values
						(
							@ObjectID,
							convert(varchar(10) , @VarCallDate, 120 ),
							10210, -- KPI Refresh Registered
							NULL,
							NULL,
							Getdate(),
							NULL,
							NULL,
							getdate(),
							-1
						)

						-------------------------------------------------------------------
						-- Get the value of the newly registered KPI Refresh Instance
						--------------------------------------------------------------------

						Select @KPIRefreshBatchID =  ObjectInstanceID
						from tb_ObjectInstance
						where ObjectID = @ObjectID
						and ObjectInstance = convert(varchar(10) , @VarCallDate, 120 )
						and statusid = 10210
				

			   End

			   -----------------------------------------------------------------------------
			   -- This scenario means that an entry already exists in the system for KPI
			   -- refresh of selected call date, and we only need to change the status of
			   -- the entry to "KPI Refresh Registered"

			   -- We should only do this update in scenario where the existing Object
			   -- instance entry is either in "Completed" or "Failed" state
			   ------------------------------------------------------------------------------

			   Else
			   Begin

					    Select @KPIRefreshBatchID =  ObjectInstanceID
						from tb_ObjectInstance
						where ObjectID = @ObjectID
						and ObjectInstance = convert(varchar(10) , @VarCallDate, 120 )
						and statusid in ( 10212	, 10213 )
						
						if ( @KPIRefreshBatchID is not NULL )
						Begin

								Update tb_ObjectInstance
								set statusid = 10210,--KPI Refresh Registered
								    ProcessStartTime = getdate(),
									ProcessEndTime = NULL,
									Remarks = NULL
								where ObjectInstanceID = @KPIRefreshBatchID			
						
						End
							
						Else
						Begin

								GOTO NEXTREC
						
						End						

			   End

			 --------------------------------------------------------------
			 -- Update this BATCHID for all the records in the KPI Refresh
			 -- Instance table for mentioned Call Date having BATCHID as
			 -- NULL
			 ---------------------------------------------------------------

			 Update tb_KPIRefreshInstance
			 set KPIRefreshBatchID = @KPIRefreshBatchID
			 where CallDate = @VarCallDate
			 and KPIRefreshBatchID is NULL

			 NEXTREC:


	   End Try

	   Begin Catch


			set @ErrorDescription = 'ERROR !!!! While creating new BATCH for KPI Refresh of Call Date : ' + 
			                         convert(varchar(30) , @VarCallDate , 120) + '. '+ 
									 ERROR_MESSAGE()
			set @ResultFlag = 1

			CLOSE db_KPIAssign_Batch_Cur 
            DEALLOCATE db_KPIAssign_Batch_Cur

			Return 1

	   End Catch


	   FETCH NEXT FROM db_KPIAssign_Batch_Cur
	   INTO @VarCallDate
 
END   

CLOSE db_KPIAssign_Batch_Cur 
DEALLOCATE db_KPIAssign_Batch_Cur
GO
