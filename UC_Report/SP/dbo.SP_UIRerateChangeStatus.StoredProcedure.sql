USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIRerateChangeStatus]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIRerateChangeStatus]
(
	@RerateID int,
	@RerateStatusID int,
	@UserID int,
	@ErrorDescription varchar(2000) output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @RerateCurrentStatus varchar(500),
        @RerateCurrentStatusID int,
		@RerateNewStatus varchar(500),
		@SendRerateAlertViaEmail int

-------------------------------------------------------------
-- Check to see if CDR Extract via email has been enabled in 
--  the system
-------------------------------------------------------------

select @SendRerateAlertViaEmail = convert(int , ConfigValue)
from Referenceserver.UC_Admin.dbo.tb_Config
where configname = 'SendRerateAlertViaEmail'
and AccessScopeID = -8 

------------------------------------------------------------
-- Check to see if the CDR Extract Id passed is valid or not
-------------------------------------------------------------

if not exists ( Select 1 from tb_Rerate where RerateID = @RerateID )
Begin

		set @ErrorDescription = 'ERROR !!!! Rerate ID passed, does not exist or is invalid'
        set @ResultFlag = 1

		Return 1

End

---------------------------------------------
-- Get the current status for the CDR Extract
----------------------------------------------

Select @RerateCurrentStatus = tbl2.RerateStatus,
       @RerateCurrentStatusID = tbl2.RerateStatusID
from tb_Rerate tbl1
inner join tb_RerateStatus tbl2 on tbl1.RerateStatusID = tbl2.RerateStatusID
where tbl1.RerateID = @RerateID


select @RerateNewStatus = RerateStatus
from tb_RerateStatus
where RerateStatusID = @RerateStatusID

-------------------------------------------------------
-- Check if there existas a valid transition of status
-- for the CDR Extract in the workflow schema
------------------------------------------------------

if not exists ( 
                  select 1 from tb_RerateStatusWorkflow 
				  where FromRerateStatusID = @RerateCurrentStatusID 
				  and ToRerateStatusID = @RerateStatusID and flag & 1 <> 1 
			  ) 
Begin

		set @ErrorDescription = 'ERROR !!!! Cannot transition Rerate job from : ( ' + @RerateCurrentStatus + ' ) ' +
		                        'status to status : ( ' + @RerateNewStatus + ' )'
        set @ResultFlag = 1

		Return 1

End

Else
Begin

		Update tb_Rerate
		set RerateStatusID = @RerateStatusID,
		    Remarks = NULL,
			RerateCompletionDate = NULL,
			ModifiedDate = getdate(),
			ModifiedByID = @UserID
        where RerateID = @RerateID

		if ( @SendRerateAlertViaEmail = 1 )
		Begin

				Exec SP_BSRerateAlert @RerateID

		End 

End
GO
