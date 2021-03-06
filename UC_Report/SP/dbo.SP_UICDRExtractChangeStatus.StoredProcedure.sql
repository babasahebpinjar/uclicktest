USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_UICDRExtractChangeStatus]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UICDRExtractChangeStatus]
(
	@CDRExtractID int,
	@CDRExtractStatusID int,
	@UserID int,
	@ErrorDescription varchar(2000) output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @CDRExtractCurrentStatus varchar(500),
        @CDRExtractCurrentStatusID int,
		@CDRExtractNewStatus varchar(500),
		@SendCDRExtractAlertViaEmail int

-------------------------------------------------------------
-- Check to see if CDR Extract via email has been enabled in 
--  the system
-------------------------------------------------------------

select @SendCDRExtractAlertViaEmail = convert(int , ConfigValue)
from Referenceserver.UC_Admin.dbo.tb_Config
where configname = 'SendCDRExtractAlertViaEmail'
and AccessScopeID = -8 

------------------------------------------------------------
-- Check to see if the CDR Extract Id passed is valid or not
-------------------------------------------------------------

if not exists ( Select 1 from tb_CDRExtract where CDRExtractID = @CDRExtractID )
Begin

		set @ErrorDescription = 'ERROR !!!! CDR Extract ID passed, does not exist or is invalid'
        set @ResultFlag = 1

		Return 1

End

---------------------------------------------
-- Get the current status for the CDR Extract
----------------------------------------------

Select @CDRExtractCurrentStatus = tbl2.CDRExtractStatus,
       @CDRExtractCurrentStatusID = tbl2.CDRExtractStatusID
from tb_CDRExtract tbl1
inner join tb_CDRExtractStatus tbl2 on tbl1.CDRExtractStatusID = tbl2.CDRExtractStatusID
where tbl1.CDRExtractID = @CDRExtractID


select @CDRExtractNewStatus = CDRExtractStatus
from tb_CDRExtractStatus
where CDRExtractStatusID = @CDRExtractStatusID

-------------------------------------------------------
-- Check if there existas a valid transition of status
-- for the CDR Extract in the workflow schema
------------------------------------------------------

if not exists ( 
                  select 1 from tb_CDRExtractStatusWorkflow 
				  where FromCDRExtractStatusID = @CDRExtractCurrentStatusID 
				  and ToCDRExtractStatusID = @CDRExtractStatusID and flag & 1 <> 1 
			  ) 
Begin

		set @ErrorDescription = 'ERROR !!!! Cannot transition CDR Extract from : ( ' + @CDRExtractCurrentStatus + ' ) ' +
		                        'status to status : ( ' + @CDRExtractNewStatus + ' )'
        set @ResultFlag = 1

		Return 1

End

Else
Begin

		Update tb_CDRExtract
		set CDRExtractStatusID = @CDRExtractStatusID,
		    Remarks = NULL,
			CDRExtractCompletionDate = NULL,
			CDRExtractFileName = NULL,
			ModifiedDate = getdate(),
			ModifiedByID = @UserID
        where CDRExtractID = @CDRExtractID

		if ( @SendCDRExtractAlertViaEmail = 1 )
		Begin

				Exec SP_BSCDRExtractAlert @CDRExtractID

		End 

End
GO
