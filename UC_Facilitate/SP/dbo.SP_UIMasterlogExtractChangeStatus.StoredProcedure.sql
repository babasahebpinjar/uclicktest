USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIMasterlogExtractChangeStatus]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIMasterlogExtractChangeStatus]
(
	@MasterlogExtractID int,
	@MasterlogExtractStatusID int,
	@UserID int,
	@ErrorDescription varchar(2000) output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @MasterlogExtractCurrentStatus varchar(500),
        @MasterlogExtractCurrentStatusID int,
		@MasterlogExtractNewStatus varchar(500),
		@SendMasterlogExtractAlertViaEmail int

-------------------------------------------------------------
-- Check to see if Masterlog Extract via email has been enabled in 
--  the system
-------------------------------------------------------------

select @SendMasterlogExtractAlertViaEmail = convert(int , ConfigValue)
from Referenceserver.UC_Admin.dbo.tb_Config
where configname = 'SendMasterlogExtractAlertViaEmail'
and AccessScopeID = -8 

------------------------------------------------------------
-- Check to see if the Masterlog Extract Id passed is valid or not
-------------------------------------------------------------

if not exists ( Select 1 from tb_MasterlogExtract where MasterlogExtractID = @MasterlogExtractID )
Begin

		set @ErrorDescription = 'ERROR !!!! Masterlog Extract ID passed, does not exist or is invalid'
        set @ResultFlag = 1

		Return 1

End

---------------------------------------------
-- Get the current status for the Masterlog Extract
----------------------------------------------

Select @MasterlogExtractCurrentStatus = tbl2.MasterlogExtractStatus,
       @MasterlogExtractCurrentStatusID = tbl2.MasterlogExtractStatusID
from tb_MasterlogExtract tbl1
inner join tb_MasterlogExtractStatus tbl2 on tbl1.MasterlogExtractStatusID = tbl2.MasterlogExtractStatusID
where tbl1.MasterlogExtractID = @MasterlogExtractID


select @MasterlogExtractNewStatus = MasterlogExtractStatus
from tb_MasterlogExtractStatus
where MasterlogExtractStatusID = @MasterlogExtractStatusID

-------------------------------------------------------
-- Check if there existas a valid transition of status
-- for the Masterlog Extract in the workflow schema
------------------------------------------------------

if not exists ( 
                  select 1 from tb_MasterlogExtractStatusWorkflow 
				  where FromMasterlogExtractStatusID = @MasterlogExtractCurrentStatusID 
				  and ToMasterlogExtractStatusID = @MasterlogExtractStatusID and flag & 1 <> 1 
			  ) 
Begin

		set @ErrorDescription = 'ERROR !!!! Cannot transition Masterlog Extract from : ( ' + @MasterlogExtractCurrentStatus + ' ) ' +
		                        'status to status : ( ' + @MasterlogExtractNewStatus + ' )'
        set @ResultFlag = 1

		Return 1

End

Else
Begin

		Update tb_MasterlogExtract
		set MasterlogExtractStatusID = @MasterlogExtractStatusID,
		    Remarks = NULL,
			MasterlogExtractCompletionDate = NULL,
			MasterlogExtractFileName = NULL,
			ModifiedDate = getdate(),
			ModifiedByID = @UserID
        where MasterlogExtractID = @MasterlogExtractID

		if ( @SendMasterlogExtractAlertViaEmail = 1 )
		Begin

				Exec SP_BSMasterlogExtractAlert @MasterlogExtractID

		End 

End
GO
