USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSExportReferenceAnalyzeRates]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSExportReferenceAnalyzeRates]
(
	@OfferID int,
	@UserID int,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @FileExists int,
		@cmd varchar(2000),
		@VendorOfferLogDirectory varchar(1000),
		@OfferLogFileName varchar(1000),
		@SQLStr varchar(2000),
		@ErrorMsgStr varchar(2000),
		@ProcessErrorFlag int = 0,
		@VendorOfferWorkingDirectory varchar(1000),
		@OfferFileName varchar(500)

Declare @ErrorDescription2 varchar(2000),
        @ResultFlag2 int,
		@SourceID int,
		@OfferDate DateTime,
		@OfferContent varchar(50),
		@OfferTypeID int,
		@NumberPlanID int

---------------------------------------------------
-- Check to confirm that the offerID is not NULL
---------------------------------------------------

if ( @OfferID is NULL )
Begin
		set @ErrorDescription = 'ERROR !!! OfferID passed cannot be NULL'
		set @ResultFlag = 1
		Return 0
End

if not exists ( select 1 from tb_offer where offerID = @OfferID and offertypeID = -1 ) -- Vendor Offer
Begin

		set @ErrorDescription = 'ERROR !!! OfferID passed for the vendor offer does not exist in the system'
		set @ResultFlag = 1
		Return 0

End

------------------------------------------------
-- Get essential attributes for the offer
------------------------------------------------

select @SourceID = SourceID,
       @OfferDate = OfferDate,
	   @OfferContent = OfferContent,
	   @OfferTypeID = OfferTypeID,
	   @OfferFileName = offerfilename
from tb_Offer
where OfferID = @OfferID


Select @NumberPlanID = NumberplanID
from UC_Reference.dbo.tb_NumberPlan
where ExternalCode = @SourceID

-------------------------------------------------------------------
-- Check to ensure the previous status of the file. Only files
-- which have previous status as "Analysis Export Failed" or 
-- "Analysis Completed" qualify for anaysis and export
-------------------------------------------------------------------

Declare @PreviousOfferStatusID int

select @PreviousOfferStatusID = OfferStatusID
from tb_OfferWorkflow
where offerID = @OfferID
and ModifiedDate = 
(
	select max(ModifiedDate)
	from tb_OfferWorkflow
	where offerID = @OfferID
)

if ( @PreviousOfferStatusID not in (10,12) )
Begin

		set @ErrorDescription = 'ERROR !!! Offer not eligible for analysis and export. Status of offer has to be "Analysis Export Failed" or "Analysis Completed"'
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
from tb_RateAnalysis
where offerID = @OfferID

--------------------------
-- Rate  Table
--------------------------
 
select tbl1.*
into #TempUploadRate
from tb_RateAnalysisSummary tbl1
inner join #TempUploadDestination tbl2 on tbl1.RateAnalysisID = tbl2.RateAnalysisID
where tbl2.offerID = @OfferID

----------------------------------------------------------------
--  Change the status of offer to "Analysis Export InProgress"
----------------------------------------------------------------

Insert into tb_OfferWorkflow
(
	OfferID,
	OfferStatusID,
	ModifiedDate,
	ModifiedByID
)
Values
(
	@OfferID,
	11 ,-- Analysis Export InProgress
	getdate(),
	@UserID
)

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

set @VendorOfferLogDirectory = @VendorOfferWorkingDirectory + 'Log\'

----------------------------------------------
-- Check if the directory exists and is valid
----------------------------------------------

if ( RIGHT(@VendorOfferLogDirectory , 1) <> '\' )
     set @VendorOfferLogDirectory = @VendorOfferLogDirectory + '\'


set @cmd = 'dir ' + '"' + @VendorOfferLogDirectory + '"' + '/b'
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
       set @ErrorDescription = 'Error!!! Vendor Offer log Directory ' + @VendorOfferLogDirectory + ' does not exist or is invalid'
       set @ResultFlag = 1
       Drop table #tempCommandoutput
       set @ProcessErrorFlag = 1
	   GOTO PROCESSEND
End

Drop table #tempCommandoutput

set @OfferLogFileName = @VendorOfferLogDirectory + Replace(@OfferFileName , '.offr' , '.log')

----------------------------------------------------
-- Add an Entry into the Log File indicating that
-- Offer Analysis and Export is being Run
----------------------------------------------------

Exec UC_Admin.dbo.SP_LogMessage NULL , @OfferLogFileName
set @ErrorMsgStr = '==============================================================='
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName

set @ErrorMsgStr = '******************** REFERENCE RATE EXPORT *******************'
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName

set @ErrorMsgStr = '==============================================================='
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName

set @ErrorMsgStr = 'Run Date is : ' + convert(varchar(100) , getdate() , 120)
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName

set @ErrorMsgStr = '==============================================================='
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName

---------------------------------------------------------------
-- Open a transaction for all the data manipulations perfromed
---------------------------------------------------------------


Begin Transaction ReferenceRatesExport

---------------------------------------------------------------------------
-- ********************* HANDLE UPLOAD RATES ***********************
---------------------------------------------------------------------------

Begin Try

	Exec SP_BSUploadReferenceAnalyzeRates @OfferID , @UserID

End Try

Begin Catch

		set @ErrorMsgStr = '	ERROR !!! Export of Analyzed Reference Rates Failed.' + ERROR_MESSAGE()
		Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName

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
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName


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

		Insert into tb_OfferWorkflow
		(
			OfferID,
			OfferStatusID,
			ModifiedDate,
			ModifiedByID
		)
		Values
		(
			@OfferID,
			12 ,-- Analysis Export Failed
			getdate(),
			@UserID
		)

End

Else
Begin


		-------------------------------------------------------
		--  Change the status of offer to "Analysis Exported "
		-------------------------------------------------------

		Insert into tb_OfferWorkflow
		(
			OfferID,
			OfferStatusID,
			ModifiedDate,
			ModifiedByID
		)
		Values
		(
			@OfferID,
			13 ,-- Analysis Exported
			getdate(),
			@UserID
		)

End


---------------------------------------------
-- Remove temporary tables created for offer
-- processing
---------------------------------------------
 
 drop table #TempUploadDestination
 drop table #TempUploadRate 

 return 0
GO
