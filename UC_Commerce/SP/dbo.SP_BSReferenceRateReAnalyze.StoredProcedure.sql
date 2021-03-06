USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSReferenceRateReAnalyze]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
	CREATE Procedure [dbo].[SP_BSReferenceRateReAnalyze]
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
	-- Get essential attributes for the Source
	------------------------------------------------

	Declare @RatePlanID int,
			@CalltypeID int

	select @SourceID = SourceID,
		   @AnalysisStartDate = AnalysisStartDate,
		   @AnalysisType = AnalysisType
	from tb_NumberPlanAnalysis
	where NumberPlanAnalysisID = @NumberPlanAnalysisID


	Select @NumberPlanID = NumberplanID
	from UC_Reference.dbo.tb_NumberPlan
	where ExternalCode = @SourceID

	select @RatePlanID = RatePlanID,
		   @CalltypeId = CallTypeID
	from tb_Source
	where SourceID = @SourceID

	-------------------------------------------------------------------
	-- Check to ensure the previous status of the file. Only files
	-- which have previous status as "Analysis Failed" or "Export Successful"
	-- qualify for Reference rate analysis
	-------------------------------------------------------------------

	Declare @PreviousNPAnalysisStatusID int

	select @PreviousNPAnalysisStatusID = AnalysisStatusID
	from tb_NumberPlanAnalysis
	where NumberPlanAnalysisID = @NumberPlanAnalysisID


	if ( @PreviousNPAnalysisStatusID not in (1,3) )
	Begin

			set @ErrorDescription = 'ERROR !!!  Reference rate Reanalysis not possible. Status of Analysis has to be "Analysis Registered" or "Analysis Failed"'
			set @ResultFlag = 1
			Return 0

	End

	--------------------------------------------------------------
	-- Empty the Rate ReAnalysis data of any instance related to
	-- previous run
	--------------------------------------------------------------

	Delete from tb_RateReAnalysisDetail
	where NumberPlanAnalysisID = @NumberPlanAnalysisID

	Delete from tb_RateReAnalysisRate
	where NumberPlanAnalysisID = @NumberPlanAnalysisID

	Delete tbl1 
	from tb_RateReAnalysisSummary tbl1
	inner join tb_RateReAnalysis tbl2 on tbl1.RateReAnalysisID = tbl2.RateReAnalysisID
	where tbl2.NumberPlanAnalysisID = @NumberPlanAnalysisID

	Delete from tb_RateReAnalysis
	where NumberPlanAnalysisID = @NumberPlanAnalysisID


	-------------------------------------------------------
	--  Change the status of offer to "Analysis InProgress"
	-------------------------------------------------------

	Update tb_NumberPlanAnalysis
	set AnalysisStatusID = 2, -- Analysis InProgress,
		ModifiedByID = @UserID,
		ModifiedDate = getdate()
	where NumberPlanAnalysisID = @NumberPlanAnalysisID


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
	-- Analysis statistics
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
		   set @ErrorDescription = 'Error!!!Number Plan Analysis log Directory ' + @NPAnalysisLogDirectory + ' does not exist or is invalid'
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

	set @ErrorMsgStr = '****************** REFERENCE RATE ANALYSIS *****************'
	Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @NPAnalysisLogFileName

	set @ErrorMsgStr = '==============================================================='
	Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @NPAnalysisLogFileName

	set @ErrorMsgStr = 'Run Date is : ' + convert(varchar(100) , getdate() , 120)
	Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @NPAnalysisLogFileName

	set @ErrorMsgStr = '==============================================================='
	Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @NPAnalysisLogFileName


	---------------------------------------------------------------------
	-- Look through the rate tables for the selected vendor to find 
	-- out the Country Codes and Effective dates for which the Number 
	-- plan reanalysis needs to be run
	--------------------------------------------------------------------- 

	if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAnalysisCountryCode') )
		Drop table #TempAnalysisCountryCode

	Create table #TempAnalysisCountryCode
	(
		CountryCode varchar(100),
		EffectiveDate datetime
	)

	insert into #TempAnalysisCountryCode
	( CountryCode , EffectiveDate )
	select Distinct cou.CountryCode , rt.BeginDate
	from UC_Reference.dbo.tb_Rate rt
	inner join UC_Reference.dbo.tb_Destination Vdest on rt.DestinationID = Vdest.DestinationID
	inner join UC_Reference.dbo.tb_Country cou on Vdest.CountryID = cou.CountryID
	where Vdest.numberplanid = @NumberPlanID
	and rt.RatePlanID = @RatePlanID
	and rt.CalltypeID = @CalltypeID
	and 
	 (
		( @AnalysisStartDate between rt.BeginDate and isnull (rt.EndDate , @AnalysisStartDate ))
		or
		( 
		   rt.Begindate >= @AnalysisStartDate 
		   and 
		   (rt.EndDate is NULL or rt.EndDate >= @AnalysisStartDate ) 
		 )
	 )

	-----------------------------------------------------------------
	-- Get all the distinct Effective dates from Dialed Digit table
	-- for any break out changes
	-----------------------------------------------------------------

	insert into #TempAnalysisCountryCode
	( CountryCode , EffectiveDate )
	select Distinct tbl1.CountryCode , tbl1.EffectiveDate
	from
	(
		select Distinct cou.CountryCode , dd.BeginDate as EffectiveDate
		from UC_Reference.dbo.tb_DialedDigits dd
		inner join UC_Reference.dbo.tb_Destination dest on dd.DestinationID = dest.DestinationID
		inner join UC_Reference.dbo.tb_Country cou on dest.countryid = cou.CountryID
		where dest.numberplanid = @NumberPlanID
		and 
		 (
			( @AnalysisStartDate between dd.BeginDate and isnull (dd.EndDate , @AnalysisStartDate ))
			or
			( 
			   dd.Begindate >= @AnalysisStartDate 
			   and 
			   (dd.EndDate is NULL or dd.EndDate >= @AnalysisStartDate ) 
			 )
		 )
	) tbl1
	left join #TempAnalysisCountryCode tbl2 on tbl1.CountryCode = tbl2.CountryCode 
									  and tbl1.EffectiveDate = tbl2.EffectiveDate
	where tbl2.CountryCode is NULL

	---------------------------------
	-- Print for Debugging Purposes
	---------------------------------

	--select * from #TempAnalysisCountryCode

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

	---------------------------------
	-- Print for Debugging Purposes
	---------------------------------

	--select 'After applying Max Back Date Allowed' ,* from #TempAnalysisCountryCode
	--order by countrycode

	--------------------------------------------------------------
	-- update all the records from the combination, which have
	-- effective date less than Analysis Start Date.
	-- Set the Effective date for Analysis to ANALYSIS START DATE
	--------------------------------------------------------------

	update #TempAnalysisCountryCode
	set EffectiveDate = @AnalysisStartDate
	where EffectiveDate < @AnalysisStartDate

	---------------------------------
	-- Print for Debugging Purposes
	---------------------------------

	--select distinct * from #TempAnalysisCountryCode
	--order by countrycode


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

	DECLARE db_ReAnalyze_Country CURSOR FOR  
	select Distinct CountryCode , EffectiveDate
	From #TempAnalysisCountryCode
	order by CountryCode , EffectiveDate


	OPEN db_ReAnalyze_Country   
	FETCH NEXT FROM db_ReAnalyze_Country
	INTO @VarCountryCode , @VarEffectiveDate 

	WHILE @@FETCH_STATUS = 0   
	BEGIN  

			Begin Try

				Exec SP_BSRateReAnalysisPerCCAndEffectiveDate @VarCountryCode , @VarEffectiveDate ,@NumberPlanAnalysisID , @UserID,
															@ErrorDescripton2 Output , @ResultFlag2 Output

			End Try

			Begin Catch

					set @ErrorMsgStr = '	ERROR !!! During Reference Destination Rate Analysis for Country Code .' + @VarCountryCode +
									   ' and effective date : ' + convert(varchar(20) , @VarEffectiveDate , 120) + '.' + 
									   ERROR_MESSAGE()
					Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @NPAnalysisLogFileName

					set @ErrorDescription = @ErrorMsgStr
					set @ResultFlag = 1
		
					set @ProcessErrorFlag = 1

					CLOSE db_ReAnalyze_Country  
					DEALLOCATE db_ReAnalyze_Country				

					GOTO PROCESSEND

			End Catch

			if ( @ResultFlag2 <> 0 )
			Begin 

					set @ErrorMsgStr = '	ERROR !!! During Reference Destination Rate Analysis for Country Code .' + @VarCountryCode +
									   ' and effective date : ' + convert(varchar(20) , @VarEffectiveDate , 120) + '.' 
					Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @NPAnalysisLogFileName

					Exec UC_Admin.dbo.SP_LogMessage NULL , @NPAnalysisLogFileName

					set @ErrorMsgStr = '	' + @ErrorDescription2 
					Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @NPAnalysisLogFileName

					set @ErrorDescription = @ErrorMsgStr
					set @ResultFlag = 1
		
					set @ProcessErrorFlag = 1

					CLOSE db_ReAnalyze_Country  
					DEALLOCATE db_ReAnalyze_Country				

					GOTO PROCESSEND

			End 

			FETCH NEXT FROM db_ReAnalyze_Country
			INTO @VarCountryCode , @VarEffectiveDate 
 
	END   

	CLOSE db_ReAnalyze_Country  
	DEALLOCATE db_ReAnalyze_Country

	-----------------------------------------------------------------------------
	---- ********************* HANDLE ANALYZED RATE BLENDING ********************
	-----------------------------------------------------------------------------

	Begin Try

		Exec SP_BSRateReAnalysisBlend @NumberPlanAnalysisID , @UserID

	End Try

	Begin Catch

			set @ErrorMsgStr = '	ERROR !!! During Reference Destination rate blending .' + ERROR_MESSAGE()
			Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @NPAnalysisLogFileName

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
	Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @NPAnalysisLogFileName


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

			Update tb_NumberPlanAnalysis
			set AnalysisStatusID = 3, -- Analysis Failed,
				ModifiedByID = @UserID,
				ModifiedDate = getdate()
			where NumberPlanAnalysisID = @NumberPlanAnalysisID

	End

	Else
	Begin

			-------------------------------------------------------
			--  Change the status of offer to "Analysis Completed"
			-------------------------------------------------------

			Update tb_NumberPlanAnalysis
			set AnalysisStatusID = 4, -- Analysis Completed,
				ModifiedByID = @UserID,
				ModifiedDate = getdate()
			where NumberPlanAnalysisID = @NumberPlanAnalysisID


	End

	--------------------------------------------------------
	-- Drop all the temporary tables created during the process
	-----------------------------------------------------------

	if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#TempAnalysisCountryCode') )
		Drop table #TempAnalysisCountryCode

	 return 0
GO
