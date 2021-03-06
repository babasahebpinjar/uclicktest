USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSExportReferenceReAnalyzeRates]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSExportReferenceReAnalyzeRates]
(
	@NumberPlanAnalysisID int,
	@UserID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @FileExists int,
		@cmd varchar(2000),
		@NPAnalysisLogDirectory varchar(1000),
		@NPAnalysisLogFileName varchar(1000),
		@SQLStr varchar(2000),
		@ErrorMsgStr varchar(2000),
		@ProcessErrorFlag int = 0,
		@VendorOfferWorkingDirectory varchar(1000),
		@OfferFileName varchar(500)

Declare @ErrorDescription2 varchar(2000),
        @ResultFlag2 int,
		@SourceID int,
		@AnalysisStartDate DateTime,
		@AnalysisType varchar(50),
		@OfferTypeID int,
		@NumberPlanID int

---------------------------------------------------
-- Check to confirm that the NumberPlanAnalysisID is not NULL
---------------------------------------------------

if ( @NumberPlanAnalysisID is NULL )
Begin
		set @ErrorDescription = 'ERROR !!! NumberPlanAnalysisID passed cannot be NULL'
		set @ResultFlag = 1
		Return 0
End

if not exists ( select 1 from tb_NumberPlanAnalysis where NumberPlanAnalysisID = @NumberPlanAnalysisID )
Begin

		set @ErrorDescription = 'ERROR !!! NumberPlanAnalysisID passed does not exist in the system'
		set @ResultFlag = 1
		Return 0

End

------------------------------------------------
-- Get essential attributes for the offer
------------------------------------------------

select @SourceID = SourceID,
       @AnalysisStartDate = AnalysisStartDate,
	   @AnalysisType = AnalysisType
from tb_NumberPlanAnalysis
where NumberPlanAnalysisID = @NumberPlanAnalysisID


Select @NumberPlanID = NumberplanID
from UC_Reference.dbo.tb_NumberPlan
where ExternalCode = @SourceID

-------------------------------------------------------------------
-- Check to ensure the previous status of the file. Only files
-- which have previous status as "Analysis Export Failed" or 
-- "Analysis Completed" qualify for anaysis and export
-------------------------------------------------------------------

Declare @PreviousOfferStatusID int

select @PreviousOfferStatusID = AnalysisStatusID
from tb_NumberPlanAnalysis
where NumberPlanAnalysisID = @NumberPlanAnalysisID


if ( @PreviousOfferStatusID not in (4,6) )
Begin

		set @ErrorDescription = 'ERROR !!! NP Analysis not eligible for Export. Status of NP Analysis has to be "Analysis Export Failed" or "Analysis Completed"'
		set @ResultFlag = 1
		Return 0

End

---------------------------------------------------
-- Load the data for offer from upload tables into
-- temp tables
---------------------------------------------------

--------------------------
-- Destination Table
--------------------------
 
select *
into #TempUploadDestination
from tb_RateReAnalysis
where NumberPlanAnalysisID = @NumberPlanAnalysisID

--------------------------
-- Rate  Table
--------------------------
 
select tbl1.*
into #TempUploadRate
from tb_RateReAnalysisSummary tbl1
inner join #TempUploadDestination tbl2 on tbl1.RateReAnalysisID = tbl2.RateReAnalysisID
where tbl2.NumberPlanAnalysisID = @NumberPlanAnalysisID

----------------------------------------------------------------
--  Change the status of offer to "Analysis Export InProgress"
----------------------------------------------------------------

update tb_NumberPlanAnalysis
set AnalysisStatusID = 5,
    ModifiedDate = getdate(),
	ModifiedByID = @UserID
where NumberPlanAnalysisID = @NumberPlanAnalysisID

--------------------------------------------------------
--Get the Vendor offer working directory to form the
-- full name for the offer file
--------------------------------------------------------

select @VendorOfferWorkingDirectory = configvalue
from UC_Admin.dbo.tb_Config
where ConfigName = 'VendorOfferWorkingDirectory'
and AccessScopeID = -6

if (@VendorOfferWorkingDirectory is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! System configuration parameter "VendorOfferWorkingDirectory" not defined'
	set @ResultFlag = 1
	set @ProcessErrorFlag = 1
	GOTO PROCESSEND

End

----------------------------------------------
-- Check if the directory exists and is valid
----------------------------------------------

if ( RIGHT(@VendorOfferWorkingDirectory , 1) <> '\' )
     set @VendorOfferWorkingDirectory = @VendorOfferWorkingDirectory + '\'


create table #tempCommandoutput
(
  CommandOutput varchar(500)
)

set @cmd = 'dir ' + '"' + @VendorOfferWorkingDirectory + '"' + '/b'
--print @cmd

insert into #tempCommandoutput
	Exec master..xp_cmdshell @cmd
	

if exists ( 
		select 1 from #tempCommandoutput
		where CommandOutput in (
					 'The system cannot find the file specified.',
					 'The system cannot find the path specified.',
					 'The network path was not found.'
				       )								
          )		
Begin  
       set @ErrorDescription = 'Error!!! Vendor Offer Working Directory ' + @VendorOfferWorkingDirectory + ' does not exist or is invalid'
       set @ResultFlag = 1
       Drop table #tempCommandoutput
       set @ProcessErrorFlag = 1
	   GOTO PROCESSEND
End

---------------------------------------------------------
-- Create the name of the log file for logging the 
-- file upload statistics
---------------------------------------------------------

set @NPAnalysisLogDirectory = @VendorOfferWorkingDirectory + 'Log\'

----------------------------------------------
-- Check if the directory exists and is valid
----------------------------------------------

if ( RIGHT(@NPAnalysisLogDirectory , 1) <> '\' )
     set @NPAnalysisLogDirectory = @NPAnalysisLogDirectory + '\'


set @cmd = 'dir ' + '"' + @NPAnalysisLogDirectory + '"' + '/b'
--print @cmd

delete from #tempCommandoutput

insert into #tempCommandoutput
	Exec master..xp_cmdshell @cmd
	

if exists ( 
		select 1 from #tempCommandoutput
		where CommandOutput in (
					 'The system cannot find the file specified.',
					 'The system cannot find the path specified.',
					 'The network path was not found.'
				       )								
          )		
Begin  
       set @ErrorDescription = 'Error!!! Vendor Offer log Directory ' + @NPAnalysisLogDirectory + ' does not exist or is invalid'
       set @ResultFlag = 1
       Drop table #tempCommandoutput
       set @ProcessErrorFlag = 1
	   GOTO PROCESSEND
End

Drop table #tempCommandoutput

set @NPAnalysisLogFileName = @NPAnalysisLogDirectory + 'NumberPlanAnalysis_' + convert(varchar(20) , @NumberPlanAnalysisID) + '.Log'

----------------------------------------------------
-- Add an Entry into the Log File indicating that
-- Offer Analysis and Export is being Run
----------------------------------------------------

Exec UC_Admin.dbo.SP_LogMessage NULL , @NPAnalysisLogFileName
set @ErrorMsgStr = '==============================================================='
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @NPAnalysisLogFileName

set @ErrorMsgStr = '******************** REFERENCE RATE EXPORT *******************'
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @NPAnalysisLogFileName

set @ErrorMsgStr = '==============================================================='
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @NPAnalysisLogFileName

set @ErrorMsgStr = 'Run Date is : ' + convert(varchar(100) , getdate() , 120)
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @NPAnalysisLogFileName

set @ErrorMsgStr = '==============================================================='
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @NPAnalysisLogFileName

---------------------------------------------------------------
-- Open a transaction for all the data manipulations perfromed
---------------------------------------------------------------


Begin Transaction ReferenceRatesExport

---------------------------------------------------------------------------
-- ********************* HANDLE UPLOAD RATES ***********************
---------------------------------------------------------------------------

Begin Try

	Exec SP_BSUploadReferencereAnalyzeRates @NumberPlanAnalysisID , @UserID

End Try

Begin Catch

		set @ErrorMsgStr = '	ERROR !!! Export of Analyzed Reference Rates Failed.' + ERROR_MESSAGE()
		Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @NPAnalysisLogFileName

		set @ErrorDescription = @ErrorMsgStr
		set @ResultFlag = 1
			
		Rollback Transaction ReferenceRatesExport

		set @ProcessErrorFlag = 1

		GOTO PROCESSEND

End Catch

--------------------------------------------------
-- In case of no error update the log file with
-- success info
-------------------------------------------------

set @ErrorMsgStr = '	Analyzed Reference Rates Export Successfully completed'
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @NPAnalysisLogFileName


Commit Transaction ReferenceRatesExport


PROCESSEND:

----------------------------------------------------------------
-- Change the status of offer depending upon whether upload
-- was successful or failure
----------------------------------------------------------------

if (@ProcessErrorFlag = 1 )
Begin

		------------------------------------------------------------
		--  Change the status of offer to "Analysis Export Failed"
		------------------------------------------------------------

		update tb_NumberPlanAnalysis
		set AnalysisStatusID = 6,
			ModifiedDate = getdate(),
			ModifiedByID = @UserID
		where NumberPlanAnalysisID = @NumberPlanAnalysisID

End

Else
Begin


		-------------------------------------------------------
		--  Change the status of offer to "Analysis Exported "
		-------------------------------------------------------

		update tb_NumberPlanAnalysis
		set AnalysisStatusID = 7,
			ModifiedDate = getdate(),
			ModifiedByID = @UserID
		where NumberPlanAnalysisID = @NumberPlanAnalysisID

End


---------------------------------------------
-- Remove temporary tables created for offer
-- processing
---------------------------------------------
 
 drop table #TempUploadDestination
 drop table #TempUploadRate 

 return 0
GO
