USE [UC_Operations]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSKPIRefreshInstanceInsert]    Script Date: 5/2/2020 6:25:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSKPIRefreshInstanceInsert]
(
	@InstanceID int,
	@CallDate Datetime,
	@SuccessRecords int,
	@FailedRecords int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

------------------------------------------------------------------------------------
-- Check in the KPI refresh schema to check if the Instance is already Registered
-- If there is already an instance existing then it needs to be ensured that it
-- isnt already assigned to a BATCH
------------------------------------------------------------------------------------


if not exists ( select 1 from tb_KPIRefreshInstance where ObjectInstanceID = @InstanceID and CallDate = @CallDate and KPIRefreshBatchID is NULL )
Begin

		--------------------------------------------------------------------------------------
		-- Insert the record into tb_KPIRefreshInstance table for the instance and call date	
		--------------------------------------------------------------------------------------

		Begin Try

					insert into tb_KPIRefreshInstance
					(
						ObjectInstanceID,
						CallDate,
						ModifiedDate,
						ModifiedByID,
						Flag,
						SuccessRecords,
						FailedRecords
					)
					Values
					(
						@InstanceID,
						@CallDate,
						getdate(),
						-1, -- Default it to uCLICK Administrator
						0,
						@SuccessRecords,
						@FailedRecords
					)

		End Try

		Begin Catch

				set @ErrorDescription = 'ERROR !!!! While inserting entry in KPI Refresh Schema for CDR file Instance: ' + convert(varchar(20) , @InstanceID) +
				                        ' and Call Date ' + convert(varchar(30) , @CallDate , 120) + '. ' + ERROR_MESSAGE()

				set @ResultFlag = 1

		End Catch


End

Else
Begin

		if exists (select 1 from tb_KPIRefreshInstance where ObjectInstanceID = @InstanceID and CallDate = @CallDate and KPIRefreshBatchID is NULL)
		Begin

					update tb_KPIRefreshInstance
					set SuccessRecords = @SuccessRecords,
					    FailedRecords = @FailedRecords
                    where ObjectInstanceID = @InstanceID 
					     and 
						   CallDate = @CallDate
						 and 
						   KPIRefreshBatchID is NULL

		End


End


GO
