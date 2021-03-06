USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSReferenceRateAnalyze]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSReferenceRateAnalyze]
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
-- which have previous status as "Analysis Failed" or "Export Successful"
-- qualify for Reference rate analysis
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

if ( @PreviousOfferStatusID not in (6,9) )
Begin

		set @ErrorDescription = 'ERROR !!! Offer not eligible for Reference rate analysis. Status of offer has to be "Analysis Failed" or "Export Successful"'
		set @ResultFlag = 1
		Return 0

End

--------------------------------------------------------------
-- Empty the Rate Analysis data of any instance related to
-- previous run
--------------------------------------------------------------

Delete from tb_RateAnalysisDetail
where offerID = @OfferID

Delete from tb_RateAnalysisRate
where offerID = @OfferID

Delete tbl1 
from tb_RateAnalysisSummary tbl1
inner join tb_RateAnalysis tbl2 on tbl1.RateAnalysisID = tbl2.RateAnalysisID
where tbl2.OfferID = @OfferID

Delete from tb_RateAnalysis
where offerID = @OfferID

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
--  Change the status of offer to "Analysis InProgress"
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
	8 ,-- Analysis InProgress
	getdate(),
	@UserID
)

--------------------------------------------------------
-- Get the Vendor offer working directory to form the
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

set @ErrorMsgStr = '****************** REFERENCE RATE ANALYSIS *****************'
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName

set @ErrorMsgStr = '==============================================================='
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName

set @ErrorMsgStr = 'Run Date is : ' + convert(varchar(100) , getdate() , 120)
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName

set @ErrorMsgStr = '==============================================================='
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName


---------------------------------------------------------------------
-- Look through the destination and dialed Digit tables for the
-- uploaded offer to find out the Country Codes and Effective
-- dates for which the rate analysis needs to be run
--------------------------------------------------------------------- 

Create table #TempAnalysisCountryCode
(
	CountryCode varchar(100),
	EffectiveDate datetime
)


insert into #TempAnalysisCountryCode
( CountryCode , EffectiveDate )
select Distinct cou.CountryCode , dest.EffectiveDate
from #TempUploadDestination dest
inner join UC_Reference.dbo.tb_Destination refdest on dest.DestinationID = refdest.DestinationID
inner join UC_Reference.dbo.tb_Country cou on refdest.CountryID = cou.CountryID


insert into #TempAnalysisCountryCode
( CountryCode , EffectiveDate )
select Distinct tbl1.CountryCode , tbl1.EffectiveDate
from #TempUploadBreakout tbl1
left join #TempAnalysisCountryCode tbl2 on tbl1.CountryCode = tbl2.CountryCode 
                                  and tbl1.EffectiveDate = tbl2.EffectiveDate
where tbl2.CountryCode is NULL

---------------------------------
-- Print for Debugging Purposes
---------------------------------

select * from #TempAnalysisCountryCode

---------------------------------------------------------
-- Check the MaxAnalysisBackDaysAllowed parameter and
-- adjust the Effective dates accordingly
---------------------------------------------------------

Declare @MaxAnalysisBackDaysAllowed int,
        @MaxAnalysisBackDate date

select @MaxAnalysisBackDaysAllowed = convert(int , ConfigValue)
from UC_Admin.dbo.tb_Config
where ConfigName = 'MaxAnalysisBackDaysAllowed'
and AccessScopeID = -6 


if (@MaxAnalysisBackDaysAllowed is NULL )
	Set @MaxAnalysisBackDaysAllowed = 0

set @MaxAnalysisBackDaysAllowed = -1 * @MaxAnalysisBackDaysAllowed
set @MaxAnalysisBackDate = convert(date ,DateAdd(dd , @MaxAnalysisBackDaysAllowed , getdate() ))

------------------------------------------------------
-- Update all the effective dates lesser than the
-- MaxAnalysisBackDate
------------------------------------------------------

update #TempAnalysisCountryCode
set EffectiveDate = @MaxAnalysisBackDate
where EffectiveDate < @MaxAnalysisBackDate

-------------------------------------------------------------------------
-- Open a cursor to traverse through all the combinations of country codes
-- and effective dates to perfrom the reference destination rate analysis
--------------------------------------------------------------------------

Declare @VarCountryCode varchar(100),
        @VarEffectiveDate datetime,
		@ErrorDescripton2 varchar(2000)

---------------------------------------------------------------
-- Open a cursor for all the data manipulations performed
---------------------------------------------------------------

DECLARE db_Analyze_Country CURSOR FOR  
select Distinct CountryCode , EffectiveDate
From #TempAnalysisCountryCode
order by CountryCode , EffectiveDate


OPEN db_Analyze_Country   
FETCH NEXT FROM db_Analyze_Country
INTO @VarCountryCode , @VarEffectiveDate 

WHILE @@FETCH_STATUS = 0   
BEGIN  

		Begin Try

			Exec SP_BSRateAnalysisPerCCAndEffectiveDate @VarCountryCode , @VarEffectiveDate ,@OfferID , @UserID,
			                                            @ErrorDescripton2 Output , @ResultFlag2 Output

		End Try

		Begin Catch

				set @ErrorMsgStr = '	ERROR !!! During Reference Destination Rate Analysis for Country Code .' + @VarCountryCode +
				                   ' and effective date : ' + convert(varchar(20) , @VarEffectiveDate , 120) + '.' + 
				                   ERROR_MESSAGE()
				Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName

				set @ErrorDescription = @ErrorMsgStr
				set @ResultFlag = 1
		
				set @ProcessErrorFlag = 1

				CLOSE db_Analyze_Country  
				DEALLOCATE db_Analyze_Country				

				GOTO PROCESSEND

		End Catch

		if ( @ResultFlag2 <> 0 )
		Begin 

				set @ErrorMsgStr = '	ERROR !!! During Reference Destination Rate Analysis for Country Code .' + @VarCountryCode +
				                   ' and effective date : ' + convert(varchar(20) , @VarEffectiveDate , 120) + '.' 
				Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName

				Exec UC_Admin.dbo.SP_LogMessage NULL , @OfferLogFileName

				set @ErrorMsgStr = '	' + @ErrorDescription2 
				Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName

				set @ErrorDescription = @ErrorMsgStr
				set @ResultFlag = 1
		
				set @ProcessErrorFlag = 1

				CLOSE db_Analyze_Country  
				DEALLOCATE db_Analyze_Country				

				GOTO PROCESSEND

		End 

		FETCH NEXT FROM db_Analyze_Country
		INTO @VarCountryCode , @VarEffectiveDate 
 
END   

CLOSE db_Analyze_Country  
DEALLOCATE db_Analyze_Country

-----------------------------------------------------------------------------
---- ********************* HANDLE ANALYZED RATE BLENDING ********************
-----------------------------------------------------------------------------

Begin Try

	Exec SP_BSRateAnalysisBlend @OfferID , @UserID

End Try

Begin Catch

		set @ErrorMsgStr = '	ERROR !!! During Reference Destination rate blending .' + ERROR_MESSAGE()
		Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName

		set @ErrorDescription = @ErrorMsgStr
		set @ResultFlag = 1
			
		set @ProcessErrorFlag = 1

		GOTO PROCESSEND

End Catch

--------------------------------------------------
-- In case of no error update the log file with
-- success info
-------------------------------------------------

set @ErrorMsgStr = '	Reference Destination Rate Analysis Complete Successfully'
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName


PROCESSEND:

----------------------------------------------------------------
-- Change the status of offer to 'Analysis Failed' in case of
-- failure
----------------------------------------------------------------

if (@ProcessErrorFlag = 1 )
Begin

		-------------------------------------------------------
		--  Change the status of offer to "Analysis Failed"
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
			9 ,-- Analysis Failed
			getdate(),
			@UserID
		)

End

Else
Begin

		-------------------------------------------------------
		--  Change the status of offer to "Analysis Completed"
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
			10 ,-- Analysis Completed
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
 drop table #TempAnalysisCountryCode

 return 0
GO
