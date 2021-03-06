USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSAnalyseAndExportOffer]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSAnalyseAndExportOffer]
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
-- which have previous status as "Export Failed" or "Upload Successful"
-- qualify for anaysis and export
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

if ( @PreviousOfferStatusID not in (3,7) )
Begin

		set @ErrorDescription = 'ERROR !!! Offer not eligible for analysis and export. Status of offer has to be "Export Failed" or "Upload Successful"'
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
from tb_UploadDestination
where offerID = @OfferID

--------------------------
-- Rate  Table
--------------------------
 
select *
into #TempUploadRate
from tb_UploadRate
where offerID = @OfferID

--------------------------
-- Dialed Digit Table
--------------------------
 
select *
into #TempUploadBreakout
from tb_UploadBreakout
where offerID = @OfferID


-------------------------------------------------------
--  Change the status of offer to "Export InProgress"
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
	5 ,-- Export InProgress
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

set @ErrorMsgStr = '****************** ANALYSE AND EXPORT OFFER *****************'
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


Begin Transaction AnalyseAndExportOffer


---------------------------------------------------------------------------
-- ********************* HANDLE UPLOAD DESTINATIONS ***********************
---------------------------------------------------------------------------

----------------------------------------------------------
-- Analyze the upload destinations to establish all
-- destinations which are currently existing or
-- have been created newly
----------------------------------------------------------

Begin Try

	Exec SP_BSAnalyseUploadDestination @NumberPlanID , @UserID

End Try

Begin Catch

		set @ErrorMsgStr = '	ERROR !!! Analysis of Upload Destinations.' + ERROR_MESSAGE()
		Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName

		set @ErrorDescription = @ErrorMsgStr
		set @ResultFlag = 1
		
		Rollback Transaction AnalyseAndExportOffer

		set @ProcessErrorFlag = 1

		GOTO PROCESSEND

End Catch

--------------------------------------------------
-- In case of no error update the log file with
-- success info
-------------------------------------------------

set @ErrorMsgStr = '	Analysis of upload destination(s) completed successfully'
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName


-----------------------------------------------------
-- Update the data from the temp upload table to
-- the reference upload table
-----------------------------------------------------

Update tbl1
set tbl1.DestinationID = tbl2.DestinationID,
    tbl1.Flag = tbl2.Flag
from tb_UploadDestination tbl1
inner join #TempUploadDestination tbl2 on tbl1.UploadDestinationID = tbl2.UploadDestinationID

----------------------
-- Debugging Start
----------------------

select *
from tb_UploadDestination
where offerid = @OfferID

--------------------
-- Debugging End
--------------------


---------------------------------------------------------------------------
-- ********************* HANDLE UPLOAD RATES ***********************
---------------------------------------------------------------------------

Begin Try

	Exec SP_BSAnalyseUploadRates @OfferID , @UserID

End Try

Begin Catch

		set @ErrorMsgStr = '	ERROR !!! Analysis of Upload Rates.' + ERROR_MESSAGE()
		Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName

		set @ErrorDescription = @ErrorMsgStr
		set @ResultFlag = 1
			
		Rollback Transaction AnalyseAndExportOffer

		set @ProcessErrorFlag = 1

		GOTO PROCESSEND

End Catch

--------------------------------------------------
-- In case of no error update the log file with
-- success info
-------------------------------------------------

set @ErrorMsgStr = '	Analysis of upload rate(s) completed successfully'
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName


---------------------------------------------------------------------------
-- ********************* HANDLE UPLOAD BREAKOUTS ***********************
---------------------------------------------------------------------------

Begin Try

	Exec SP_BSAnalyseUploadBreakouts @OfferID , @UserID

End Try

Begin Catch

		set @ErrorMsgStr = '	ERROR !!! Analysis of Upload Breakouts.' + ERROR_MESSAGE()
		Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName

		set @ErrorDescription = @ErrorMsgStr
		set @ResultFlag = 1
			
		Rollback Transaction AnalyseAndExportOffer

		set @ProcessErrorFlag = 1

		GOTO PROCESSEND

End Catch

--------------------------------------------------
-- In case of no error update the log file with
-- success info
-------------------------------------------------

set @ErrorMsgStr = '	Analysis of upload breakout(s) completed successfully'
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName


Commit Transaction AnalyseAndExportOffer


PROCESSEND:

----------------------------------------------------------------
-- Change the status of offer depending upon whether upload
-- was successful or failure
----------------------------------------------------------------

if (@ProcessErrorFlag = 1 )
Begin

		-------------------------------------------------------
		--  Change the status of offer to "Export Failed"
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
			7 ,-- Export Failed
			getdate(),
			@UserID
		)

End

Else
Begin


		-------------------------------------------------------
		--  Change the status of offer to "Export Successful"
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
			6 ,-- Upload Successful
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
 drop table #TempUploadBreakout

 return 0
GO
