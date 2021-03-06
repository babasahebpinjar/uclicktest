USE [UC_Report]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMasterlogExtracMain]    Script Date: 5/2/2020 6:39:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_BSMasterlogExtracMain]
(
	@MasterlogExtractID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output 
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @UserID int,
        @SendMasterlogExtractAlertViaEmail int,
		@MasterlogExtractName varchar(500),
		@RowsCount int

-------------------------------------------------------------
-- Check to see if Masterlog Extract via email has been enabled in 
--  the system
-------------------------------------------------------------

select @SendMasterlogExtractAlertViaEmail = convert(int , ConfigValue)
from Referenceserver.UC_Admin.dbo.tb_Config
where configname = 'SendMasterlogExtractAlertViaEmail'
and AccessScopeID = -8 

---------------------------------------------------------------
-- Check to see that the passed Masterlog Extract ID exists in the
-- system, and is in Registered state
----------------------------------------------------------------

if not exists ( select 1 from tb_MasterlogExtract where MasterlogExtractID = @MasterlogExtractID and MasterlogExtractStatusID = -1 ) -- Registered
Begin

		set @ErrorDescription = 'ERROR !!!! There is either no Masterlog extract in the system for passed ID, or it is not in Registered state'
		set @ResultFlag = 1
		GOTO ENDPROCESS

End

-------------------------------------------------
-- Get the USERID details from the Masterlog Extract
--------------------------------------------------

select @UserID = UserID,
       @MasterlogExtractName = MasterlogExtractName
from tb_MasterlogExtract
where MasterlogExtractID = @MasterlogExtractID

--------------------------------------------------------------
-- Get the essential parameters for initiating the Masterlog Extract
--------------------------------------------------------------

Declare @CallID varchar(max),
        @CallingNumber varchar(max), 
   	    @CalledNumber varchar(max),
		@MasterlogExtractFileName varchar(1000)

Select  @CallID  = CallID,
        @CallingNumber = CallingNumber,
   	    @CalledNumber = CalledNumber
From tb_MasterlogExtractParamList
where MasterlogExtractID = @MasterlogExtractID

--------------------------------------------------------------
-- Change the status of the Masterlog Extract to Running and call
-- the execution procedure
---------------------------------------------------------------

Update tb_MasterlogExtract
set MasterlogExtractStatusID = -2 -- Running
where MasterlogExtractID = @MasterlogExtractID
and MasterlogExtractStatusID = -1 -- Registered

if ( @SendMasterlogExtractAlertViaEmail = 1 )
Begin

	Exec SP_BSMasterlogExtractAlert @MasterlogExtractID

End

Begin Try

		Begin

				Exec SP_BSMasterlogExtractGenerate @CallID , @CallingNumber , @CalledNumber,
											 @RowsCount Output, @MasterlogExtractFileName Output , @ErrorDescription Output , @ResultFlag Output 

		End

		if ( @ResultFlag = 1 )
		Begin

				GOTO ENDPROCESS			

		End

End Try

Begin Catch

		set @ErrorDescription = 'ERROR !!!! While executing Masterlog Extraction process. ' + ERROR_MESSAGE() + convert(varchar(10),ERROR_LINE())
		set @ResultFlag = 1
		GOTO ENDPROCESS

End Catch


---------------------------------------------------------
-- Extract the name of the Masterlog Extract file created by
-- the process
---------------------------------------------------------

--set @MasterlogExtractFileName = reverse(substring(reverse(@MasterlogExtractFileName) , 1 , charindex('\' ,reverse(@MasterlogExtractFileName)) - 1))


ENDPROCESS:

if ( @ResultFlag = 1 ) -- Failure
Begin
	
	print '----- Failed ---->>>'

	print @ErrorDescription + ' - Rows ' +convert(varchar(10),@RowsCount)

	Update tb_MasterlogExtract
	set MasterlogExtractStatusID = -4, -- Failed
	    Remarks = ISNULL(@ErrorDescription, '')   + ' Number of Records ' +convert(varchar(100),@RowsCount),
		ModifiedDate = Getdate(),
		ModifiedByID = -1
    where MasterlogExtractID = @MasterlogExtractID
	and MasterlogExtractStatusID = -2 -- Running

End


if ( @ResultFlag = 0 ) -- Success
Begin
	
	print '----- Success ----'
	print ISNULL(@ErrorDescription, '')   + ' - Number of Records ' +convert(varchar(10),@RowsCount)
	
	Update tb_MasterlogExtract
	set MasterlogExtractStatusID = -3, -- Success,
	    Remarks = ISNULL(@ErrorDescription, '')   + ' Number of Records ' +convert(varchar(10),@RowsCount),
	    MasterlogExtractCompletionDate = Getdate(),
		MasterlogExtractFileName = @MasterlogExtractFileName,
		ModifiedDate = Getdate(),
		ModifiedByID = -1
    where MasterlogExtractID = @MasterlogExtractID
	and MasterlogExtractStatusID = -2 -- Running
	

End 

--------------------------------------------------------
-- Send and email alert regarding the status of extract  
--------------------------------------------------------

if ( @SendMasterlogExtractAlertViaEmail = 1 )
Begin

	Exec SP_BSMasterlogExtractAlert @MasterlogExtractID

End 

Return 0
GO
