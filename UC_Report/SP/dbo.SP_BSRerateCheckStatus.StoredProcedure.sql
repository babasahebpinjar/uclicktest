USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSRerateCheckStatus]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSRerateCheckStatus]
As

Declare @RerateID int,
        @UserID int,
        @SendRerateAlertViaEmail int,
		@RerateName varchar(500)

---------------------------------------------------
-- Get the ID of the rerate job, which is currently
-- in running status
---------------------------------------------------

select @RerateID = RerateID
from tb_Rerate
where ReratestatusID = -2 -- Running

if (@RerateID is NULL )
	Return 0


-------------------------------------------------
-- Get the USERID details from the Rerate
--------------------------------------------------

select @UserID = UserID,
       @RerateName = RerateName
from tb_Rerate
where RerateID = @RerateID

-------------------------------------------------------------
-- Check to see if Rerate via email has been enabled in 
--  the system
-------------------------------------------------------------

select @SendRerateAlertViaEmail = convert(int , ConfigValue)
from Referenceserver.UC_Admin.dbo.tb_Config
where configname = 'SendRerateAlertViaEmail'
and AccessScopeID = -8 


----------------------------------------------------------------
-- Check the status of all the files under the rerate job that
-- qualified for rerating
-----------------------------------------------------------------

------------------------------------------------------------------------
-- If there are files still in Registered or running state, then
-- let the status of the rerate job remain as running
-------------------------------------------------------------------------

if exists (
				Select 1
				from tb_RerateCDrFileList tbl1
				inner join ReferenceServer.UC_Operations.dbo.tb_ObjectInstance tbl2 on tbl1.CDRfileID = tbl2.ObjectInstanceID
				Where tbl1.RerateID = @RerateID
				and tbl2.statusID in (10010 , 10011) -- Running or Registered
          )
Begin

    --select 'Debug' , 'Stage 1'

	Return 0 -- Exit without doing anything as the CDR files quealified for rerating are still gettiing uploaded

End

--------------------------------------------------------------------------
-- Set the status of the rerate job to failed incase there are any files
-- that have failed upload
---------------------------------------------------------------------------

Declare @CDRFileCount int,
        @RerateCDRFileCount int

if not exists (
				Select 1
				from tb_RerateCDRFileList tbl1
				inner join ReferenceServer.UC_Operations.dbo.tb_ObjectInstance tbl2 on tbl1.CDRfileID = tbl2.ObjectInstanceID
				Where tbl1.RerateID = @RerateID			
				and tbl2.statusID in (10010 , 10011) -- registered or running state
          )
Begin

    --select 'Debug' , 'Stage 2'

	Select @CDRFileCount = count(*)
	from tb_RerateCDRFileList tbl1
	inner join ReferenceServer.UC_Operations.dbo.tb_ObjectInstance tbl2 on tbl1.CDRfileID = tbl2.ObjectInstanceID
	Where tbl1.RerateID = @RerateID
	and tbl2.statusID  = 10013 -- Failed

	--select 'Debug' , @CDRFileCount

	if ( @CDRFileCount <> 0 ) --  Incase there are failures
	Begin

			--------------------------------------------------
			-- Change the status of the rerate job to Failed
			--------------------------------------------------

			Update tb_Rerate
			set RerateStatusID = -4, -- Failed
				Remarks = 
						Case
							When Remarks is NULL Then  'ERROR !!!!! There are ' + convert(varchar(20) ,@CDRFileCount)  + ' CDR files that have failed reupload into system.'
							Else Remarks + ' ERROR !!!!! There are ' + convert(varchar(20) ,@CDRFileCount)  + ' CDR files that have failed reupload into system.'
						End,
				ModifiedDate = Getdate(),
				ModifiedByID = -1
			where RerateID = @RerateID
			and RerateStatusID = -2 -- Running

			--------------------------------------------------------
			-- Send and email alert regarding the status of extract  
			--------------------------------------------------------

			if ( @SendRerateAlertViaEmail = 1 )
			Begin

				Exec SP_BSRerateAlert @RerateID

			End 

			Return 0 -- Exit after setting the status of the rerste job to Failed

	End		

End

------------------------------------------------------------------------------
-- Change the status of the Rerate job to completed, incase all the CDR files
-- have been uploaded successfully
------------------------------------------------------------------------------
Declare @TotalCDRRec int

Select @CDRFileCount = count(*)
from tb_RerateCDrFileList tbl1
inner join ReferenceServer.UC_Operations.dbo.tb_ObjectInstance tbl2 on tbl1.CDRfileID = tbl2.ObjectInstanceID
Where tbl1.RerateID = @RerateID
and tbl2.statusID  = 10012 -- Completed

select @RerateCDRFileCount = count(*)
from tb_RerateCDRFileList
where RerateID = @RerateID

select 'Debug' , @CDRFileCount , @RerateCDRFileCount

if (@CDRFileCount = @RerateCDRFileCount )
Begin

    --select 'Debug' , 'Stage 3'

    select @TotalCDRRec = sum(tbl2.Measure1)
	from tb_RerateCDRFileList tbl1
	inner join ReferenceServer.UC_Operations.dbo.tb_ObjectInstanceTaskLog tbl2 on tbl1.CDRFileID = tbl2.ObjectInstanceID
									   and tbl2.TaskName = 'Upload RAW CDR File'
	where tbl1.RerateID = @RerateID

	--------------------------------------------------
	-- Change the status of the rerate job to success
	--------------------------------------------------

	Update tb_Rerate
	set RerateStatusID = -3, -- Success Completed 
		Remarks = 
				Case
					When Remarks is NULL Then  'Total number of records rerated =  ' + convert(varchar(20) ,@TotalCDRRec)
					Else Remarks + ' Total number of records rerated =  ' + convert(varchar(20) ,@TotalCDRRec)
				End,
		RerateCompletionDate = getdate(),
		ModifiedDate = Getdate(),
		ModifiedByID = -1
    where RerateID = @RerateID
	and RerateStatusID = -2 -- Running

	-------------------------------------------------------
	-- Delete the CDR File List for the Successful Rerate 
	-- job as all the CDR files would have got uploaded
	-- successfully
	-------------------------------------------------------

	Delete from tb_RerateCDRFileList
	Where RerateID = @RerateID

	--------------------------------------------------------
	-- Send and email alert regarding the status of extract  
	--------------------------------------------------------

	if ( @SendRerateAlertViaEmail = 1 )
	Begin

		Exec SP_BSRerateAlert @RerateID

	End 
	
	Return 0

End




GO
