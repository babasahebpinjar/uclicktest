USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSRerateRegisterMain]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSRerateRegisterMain]
(
	@RerateID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output 
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @UserID int,
        @SendRerateAlertViaEmail int,
		@RerateName varchar(500),
        @CDRFileCount int

-------------------------------------------------------------
-- Check to see if Rerate via email has been enabled in 
--  the system
-------------------------------------------------------------

select @SendRerateAlertViaEmail = convert(int , ConfigValue)
from Referenceserver.UC_Admin.dbo.tb_Config
where configname = 'SendRerateAlertViaEmail'
and AccessScopeID = -8 

---------------------------------------------------------------
-- Check to see that the passed Rerate ID exists in the
-- system, and is in Registered state
----------------------------------------------------------------

if not exists ( select 1 from tb_Rerate where RerateID = @RerateID and RerateStatusID = -1 ) -- Registered
Begin

		set @ErrorDescription = 'ERROR !!!! There is either no Rerate in the system for passed ID, or it is not in Registered state'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End

-------------------------------------------------
-- Get the USERID details from the Rerate
--------------------------------------------------

select @UserID = UserID,
       @RerateName = RerateName
from tb_Rerate
where RerateID = @RerateID


--------------------------------------------------------------------
-- this logic is to handle the scenario, where the rerate job has
-- been re-registered again due to failure of some CDr files in the 
-- previous run.
-- We need to ensure that only the failed CDR files are registered 
-- again for upload
--------------------------------------------------------------------

Begin Try

		if exists (
						select 1
						from tb_RerateCDRFileList tbl1
						inner join ReferenceServer.UC_Operations.dbo.tb_ObjectInstance tbl2 on tbl1.CDRfileID = tbl2.ObjectInstance
						Where tbl1.RerateId = @RerateID
						and tbl2.statusid = 10013 -- Failed
				  )
		Begin

					------------------------------------------------------------
					-- Change the status of the failed CDR files to Registered
					------------------------------------------------------------
					update tbl2
					set statusid = 10012
					from tb_RerateCDRFileList tbl1
					inner join ReferenceServer.UC_Operations.dbo.tb_ObjectInstance tbl2 on tbl1.CDRfileID = tbl2.ObjectInstance
					Where tbl1.RerateId = @RerateID
					and tbl2.statusid = 10013 


					select @CDRFileCount = count(*)
					from tb_RerateCDRFileList
					where RerateID = @RerateID

					set @ErrorDescription = 'Total CDR Files qualified for rerating : ' + convert(varchar(100) , @CDRFileCount) + '.'

					GOTO ENDPROCESS


		End

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!!! While Re-registering Rerate job for running. ' + ERROR_MESSAGE()
		set @ResultFlag = 1

		GOTO ENDPROCESS


End Catch

---------------------------------------------------------------------------------------------
-- This is a case of new Rerate job, which is coming into running state for the first time
-- or no CDR files had been selected during the previous extraction process
---------------------------------------------------------------------------------------------

Begin Try


		Exec SP_BSRerateRegister @RerateID,@ErrorDescription Output , @ResultFlag Output


		if ( @ResultFlag = 1 )
		Begin

				------------------------------------------------------------
				-- Delete CDR File list, incase it was selected and stored 
				------------------------------------------------------------

				Delete from tb_RerateCDRFileList
				where RerateID = @RerateID

				GOTO ENDPROCESS			

		End

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!!! While Registering Rerate job for running. ' + ERROR_MESSAGE()
		set @ResultFlag = 1

		------------------------------------------------------------
		-- Delete CDR File list, incase it was selected and stored 
		------------------------------------------------------------

		Delete from tb_RerateCDRFileList
		where RerateID = @RerateID

		GOTO ENDPROCESS

End Catch

------------------------------------------------------
-- Incase the rerate job registration process was 
-- successful and qualified CDR files were extracted,
-- We need to change status of CDR files to 'Registered'
-------------------------------------------------------
-- NOTE : There is a reason to move the updte from the 
-- REGISTER procedure to REGISTER MAIN procedure.

-- We want to ensure that after all the steps in registration of rerate job
-- are completed successfully then only we change the status
-- of the CDR files to REGISTERED so that they can start
-- getting uploaded
--------------------------------------------------------
Update tbl1
set statusid = 10010
from ReferenceServer.UC_Operations.dbo.tb_ObjectInstance tbl1
inner join tb_RerateCDRfileList tbl2 on tbl1.ObjectInstanceID = tbl2.CDRFileID
where tbl2.RerateID = @RerateID



ENDPROCESS:

if ( @ResultFlag = 1 ) -- Failure
Begin

		Update tb_Rerate
		set RerateStatusID = -4, -- Failed
			Remarks = @ErrorDescription,
			ModifiedDate = Getdate(),
			ModifiedByID = -1
		where RerateID = @RerateID
		and RerateStatusID = -1 -- Registered

		--------------------------------------------------------
		-- Send and email alert regarding the status of extract  
		--------------------------------------------------------

		if ( @SendRerateAlertViaEmail = 1 )
		Begin

			Exec SP_BSRerateAlert @RerateID

		End 

End

Else
Begin

		------------------------------------------------------------
		-- Change the status of the Rerate to Running 
		-------------------------------------------------------------

		Update tb_Rerate
		set RerateStatusID = -2, -- Running
		    Remarks = @ErrorDescription,
			ModifiedDate = Getdate()
		where RerateID = @RerateID
		and RerateStatusID = -1 -- Registered

		if ( @SendRerateAlertViaEmail = 1 )

		Begin

			Exec SP_BSRerateAlert @RerateID

		End


End

Return 0
GO
