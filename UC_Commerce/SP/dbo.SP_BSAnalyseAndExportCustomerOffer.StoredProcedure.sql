USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSAnalyseAndExportCustomerOffer]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSAnalyseAndExportCustomerOffer]
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
		@CustomerOfferLogDirectory varchar(1000),
		@OfferLogFileName varchar(1000),
		@SQLStr varchar(2000),
		@ErrorMsgStr varchar(2000),
		@ProcessErrorFlag int = 0,
		@CustomerOfferWorkingDirectory varchar(1000),
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

if not exists ( select 1 from tb_offer where offerID = @OfferID and offertypeID = -2 ) -- Customer Offer
Begin

		set @ErrorDescription = 'ERROR !!! OfferID passed for the Customer offer does not exist in the system'
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

-------------------------------------------------------------------
-- Check to ensure the previous status of the file. Only files
-- which have previous status as "Created" qualify for anaysis and
-- export
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

if ( @PreviousOfferStatusID != 14 )
Begin

		set @ErrorDescription = 'ERROR !!! Offer not eligible for export. Status of customer offer has to be "Created"'
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
	15 ,-- Export InProgress
	getdate(),
	@UserID
)

--------------------------------------------------------
--Get the customer offer working directory to form the
-- full name for the offer file
--------------------------------------------------------

select @CustomerOfferWorkingDirectory = configvalue
from UC_Admin.dbo.tb_Config
where ConfigName = 'CustomerOfferWorkingDirectory'
and AccessScopeID = -6

if (@CustomerOfferWorkingDirectory is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! System configuration parameter "CustomerOfferWorkingDirectory" not defined'
	set @ResultFlag = 1
	set @ProcessErrorFlag = 1
	GOTO PROCESSEND

End

----------------------------------------------
-- Check if the directory exists and is valid
----------------------------------------------

if ( RIGHT(@CustomerOfferWorkingDirectory , 1) <> '\' )
     set @CustomerOfferWorkingDirectory = @CustomerOfferWorkingDirectory + '\'


create table #tempCommandoutput
(
  CommandOutput varchar(500)
)

set @cmd = 'dir ' + '"' + @CustomerOfferWorkingDirectory + '"' + '/b'
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
       set @ErrorDescription = 'Error!!! Customer Offer Working Directory ' + @CustomerOfferWorkingDirectory + ' does not exist or is invalid'
       set @ResultFlag = 1
       Drop table #tempCommandoutput
       set @ProcessErrorFlag = 1
	   GOTO PROCESSEND
End

---------------------------------------------------------
-- Create the name of the log file for logging the 
-- file upload statistics
---------------------------------------------------------

set @CustomerOfferLogDirectory = @CustomerOfferWorkingDirectory + 'Log\'

----------------------------------------------
-- Check if the directory exists and is valid
----------------------------------------------

if ( RIGHT(@CustomerOfferLogDirectory , 1) <> '\' )
     set @CustomerOfferLogDirectory = @CustomerOfferLogDirectory + '\'


set @cmd = 'dir ' + '"' + @CustomerOfferLogDirectory + '"' + '/b'
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
       set @ErrorDescription = 'Error!!! Customer Offer log Directory ' + @CustomerOfferLogDirectory + ' does not exist or is invalid'
       set @ResultFlag = 1
       Drop table #tempCommandoutput
       set @ProcessErrorFlag = 1
	   GOTO PROCESSEND
End

Drop table #tempCommandoutput

set @OfferLogFileName = @CustomerOfferLogDirectory + Replace(@OfferFileName , '.offr' , '.log')

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
-- ********************* HANDLE UPLOAD RATES ***********************
---------------------------------------------------------------------------

Begin Try

	Exec SP_BSAnalyseUploadCustomerOfferRates @OfferID , @UserID

End Try

Begin Catch

		set @ErrorMsgStr = '	ERROR !!! Analysis and Export of Upload Rates.' + ERROR_MESSAGE()
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

set @ErrorMsgStr = '	Analysis and Export of upload rate(s) completed successfully'
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName


Commit Transaction AnalyseAndExportOffer


PROCESSEND:

----------------------------------------------------------------
-- Change the status of offer depending upon whether export
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
			17 ,-- Export Failed
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
			16 ,-- Export Successful
			getdate(),
			@UserID
		)

End


---------------------------------------------
-- Remove temporary tables created for offer
-- processing
---------------------------------------------
 if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempUploadDestination') )
 drop table #TempUploadDestination

 if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempUploadRate') )
 drop table #TempUploadRate 

 if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempUploadBreakout') )
 drop table #TempUploadBreakout

 return 0
GO
