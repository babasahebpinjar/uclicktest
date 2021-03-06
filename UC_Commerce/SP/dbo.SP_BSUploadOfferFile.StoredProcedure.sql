USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSUploadOfferFile]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSUploadOfferFile]
(
	@OfferID int,
	@UserID int,
	@ResultFlag int Output,
	@ErrorDescription varchar(2000) Output
)
As

Declare @FileExists int,
		@cmd varchar(2000),
		@VendorOfferLogDirectory varchar(1000),
		@OfferLogFileName varchar(1000),
		@SQLStr varchar(2000),
		@ErrorMsgStr varchar(2000),
		@ProcessErrorFlag int = 0

Declare @ErrorDescription2 varchar(2000),
        @ResultFlag2 int,
		@SourceID int,
		@OfferDate DateTime
			

set @ResultFlag = 0
set @ErrorDescription = NULL


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
       @OfferDate = OfferDate
from tb_Offer
where OfferID = @OfferID

-------------------------------------------------------------------
-- Check to ensure the previous status of the file. Only files
-- which have previous status as "Created" or "Upload Failed"
-- qualify for upload
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

if ( @PreviousOfferStatusID not in (1,4) )
Begin

		set @ErrorDescription = 'ERROR !!! Offer not eligible for upload or reupload. Status of offer has to be "Created" or "Upload Failed"'
		set @ResultFlag = 1
		Return 0

End

-----------------------------------------------------
-- Remove previous run entries from the database
-----------------------------------------------------

Delete from tb_UploadRate
where offerID = @OfferID

Delete from tb_UploadBreakout
where offerID = @OfferID

Delete from tb_UploadDestination
where offerID = @OfferID

-------------------------------------------------------
--  Change the status of offer to "Upload InProgress"
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
	2 ,-- Upload InProgress
	getdate(),
	@UserID
)

--------------------------------------------------------------
-- Extract the offer file name from the vendor offer
--------------------------------------------------------------

Declare @OfferFileName varchar(500),
        @CompleteOfferFileName varchar(1000),
		@VendorOfferWorkingDirectory varchar(1000)

select @OfferFileName = offerfilename
from tb_offer
where offerID = @OfferID

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


--------------------------------------------------------
-- Form the complete offer file name and check if the 
-- file exists
--------------------------------------------------------

set @CompleteOfferFileName = @VendorOfferWorkingDirectory + @OfferFileName

set @FileExists = 0

Exec master..xp_fileexist @CompleteOfferFileName , @FileExists output  

if ( @FileExists <> 1 )
Begin

	set @ErrorDescription = 'ERROR !!! Offer file  : (' + @CompleteOfferFileName + ') does not exist or is not accessible'
	set @ResultFlag = 1
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
-- File upload is being Run
----------------------------------------------------

Exec UC_Admin.dbo.SP_LogMessage NULL , @OfferLogFileName
set @ErrorMsgStr = '==============================================================='
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName

set @ErrorMsgStr = '****************** UPLOAD VENDOR OFFER FILE *****************'
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName

set @ErrorMsgStr = '==============================================================='
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName

set @ErrorMsgStr = 'Run Date is : ' + convert(varchar(100) , getdate() , 120)
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName

set @ErrorMsgStr = '==============================================================='
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName

-----------------------------------------------------
-- Bulk upload the vendor offer file into the temp
-- schema
-----------------------------------------------------

Declare @RowTerminator varchar(10),
        @FieldTerminator varchar(10)

set @RowTerminator = '\n'
set @FieldTerminator = '|'

---------------------------------
-- Create the temp table to
-- hold the records
---------------------------------

create table #TempVendorOfferData
(
	Destination varchar(500),
	DialedDigit varchar(60),
	EffectiveDate Date,
	Rate varchar(25),
	RatingMethod varchar(100),
	RateTimeBand varchar(100)
)

create table #TempRecordCount ( DataRecord varchar(5000) )

Begin Try

	Select	@SQLStr = 'Bulk Insert  #TempVendorOfferData '+ ' From ' 
				  + '''' + @CompleteOfferFileName +'''' + ' WITH (
				  MAXERRORS = 0, FIELDTERMINATOR  = ''' + @FieldTerminator + ''','+
			  'ROWTERMINATOR    = ''' + @RowTerminator + ''''+')'

	--print @SQLStr
	Exec (@SQLStr)

	--------------------------------------------------------
	-- Buld upload records into Temp table to make sure
	-- all records have been uploaded
	--------------------------------------------------------

	Select	@SQLStr = 'Bulk Insert  #TempRecordCount '+ ' From ' 
				  + '''' + @CompleteOfferFileName +'''' + ' WITH ( '+				 
			  'MAXERRORS = 0,ROWTERMINATOR    = ''' + @RowTerminator + ''''+')'

	--print @SQLStr
	Exec (@SQLStr)

End Try

Begin Catch

	Exec UC_Admin.dbo.SP_LogMessage NULL , @OfferLogFileName
	set  @ErrorMsgStr = '	ERROR !!! Bulk upload of vendor offer file into database failed.' + ERROR_MESSAGE()
	Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName

    drop table #TempVendorOfferData
	drop table #TempRecordCount
    
	set @ProcessErrorFlag = 1

	GOTO PROCESSEND

End Catch

if ( 
	(  select count(*)  from #TempRecordCount) <>
	(  select count(*)  from #TempVendorOfferData )
   )
Begin 

	Exec UC_Admin.dbo.SP_LogMessage NULL , @OfferLogFileName
	set @ErrorMsgStr = '	ERROR !!! All records have not been exported into schema due to soem exception in format of one or more records'
	Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName

    drop table #TempVendorOfferData
	drop table #TempRecordCount

    set @ProcessErrorFlag = 1

	GOTO PROCESSEND

End    

drop table #TempRecordCount

------------------------------------------------------
-- Alter the data table to add columns for:
-- CountryCode , ErrorMessage ,ErrorCode
------------------------------------------------------

Alter table #TempVendorOfferData add CountryCode varchar(20)
Alter table #TempVendorOfferData add ErrorMessage varchar(2000)
Alter table #TempVendorOfferData add ErrorCode varchar(20)

--------------------------------------------------------
-- Update the Country code for all the exported records
--------------------------------------------------------

Declare @TempCountryCodeStr varchar(60),
        @VarCountryCode varchar(20),
        @CountryCode varchar(15)

create table #TempAllCountryCode ( CountryCode varchar(20) )

------------------------------------------
-- Get list of country codes from the
-- reference data
------------------------------------------

Declare GetAllCountryCode_Cur Cursor For
select countrycode
from UC_Reference.dbo.tb_Country
where flag & 1 <> 1

Open GetAllCountryCode_Cur
Fetch Next From GetAllCountryCode_Cur
Into @VarCountryCode


While @@FETCH_STATUS = 0
Begin

    set @TempCountryCodeStr = @VarCountryCode

	while ( charindex(',' , @VarCountryCode ) <> 0 )
	Begin

            set @TempCountryCodeStr = substring(@VarCountryCode , 1 , charindex(',' , @VarCountryCode ) - 1 )
			insert into #TempAllCountryCode values ( @TempCountryCodeStr )
            set @VarCountryCode = substring(@VarCountryCode , charindex(',' , @VarCountryCode ) + 1 , Len(@VarCountryCode) )
	End

	insert into #TempAllCountryCode values ( @VarCountryCode )
 
	Fetch Next From GetAllCountryCode_Cur
	Into @VarCountryCode

End

Close GetAllCountryCode_Cur
Deallocate GetAllCountryCode_Cur


--------------------------------
-- Update the country codes
--------------------------------

update #TempVendorOfferData
set CountryCode = 'NOT EXIST'

Declare Update_CountryCode_Cur Cursor For
select countrycode
from #TempAllCountryCode
order by len(countrycode) desc

Open Update_CountryCode_Cur
Fetch Next From Update_CountryCode_Cur
Into @VarCountryCode


While @@FETCH_STATUS = 0
Begin

	update #TempVendorOfferData
        set CountryCode = @VarCountryCode
	where CountryCode = 'NOT EXIST'
	and substring(DialedDigit , 1 , len(@VarCountryCode) ) = @VarCountryCode
 
	Fetch Next From Update_CountryCode_Cur
	Into @VarCountryCode

End

Close Update_CountryCode_Cur
Deallocate Update_CountryCode_Cur

drop table #TempAllCountryCode

-----------------------------------------------------
-- Validate the contents of the offer to ensure that
-- all data is syntactically correct
-----------------------------------------------------

Begin Try

        set @ResultFlag2 = 0
		set @ErrorDescription2 = NULL

		Exec SP_BSVerifyOfferContent @OfferID , @OfferLogFileName , @UserID, @ResultFlag2 Output , @ErrorDescription2 Output

End Try

Begin Catch

	Exec UC_Admin.dbo.SP_LogMessage NULL , @OfferLogFileName
	set @ErrorMsgStr = '	ERROR !!! During verification of offer content.' + ERROR_MESSAGE()
	Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName		

    set @ProcessErrorFlag = 1

	GOTO PROCESSEND

End Catch

if (@ResultFlag2 <> 0 )
Begin

	Exec UC_Admin.dbo.SP_LogMessage NULL , @OfferLogFileName
	set @ErrorMsgStr = '	ERROR !!! During verification of offer content.'
	Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName		

    set @ProcessErrorFlag = 1

	GOTO PROCESSEND

End


if not exists ( select 1 from #TempVendorOfferData where ErrorMessage is not NULL)
Begin

	set @ErrorMsgStr = '	INFO !!! Validation of records completed. No errors encountered.'
	Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName

End

----------------------------------------------------------------
-- Load the offer data into schema tables separately for
-- destination , rates and dialeddigits
----------------------------------------------------------------

Begin Try

		---------------
		-- Destination
		---------------

		insert into tb_UploadDestination
		(	
			OfferID,
			SourceID,
			OfferDate,
			Destination,
			DestinationID,
			EffectiveDate,
			RatingMethodID,
			DestinationTypeID,
			ModifiedDate,
			ModifiedByID,
			Flag
		)
		Select Distinct
		@OfferID,
		@SourceID,
		@OfferDate,
		Destination,
		NULL,
		EffectiveDate,
		tbl2.RatingMethodID,
		NULL,
		Getdate(),
		@UserID,
		0
		from #TempVendorOfferData tbl1
		inner join UC_REference.dbo.tb_RatingMethod tbl2 on tbl1.RatingMethod = tbl2.RatingMethod


		-----------
		-- Rate
		-----------

		insert into tb_uploadRate
		(
			OfferID,
			UploadDestinationID,
			Rate,
			RateTypeID,
			EffectiveDate,
			ModifiedDate,
			ModifiedByID,
			Flag
		)
		Select distinct
		@OfferID,
		tbl2.UploadDestinationID,
		convert(decimal(19,6) ,tbl1.Rate),
		tbl3.RateItemID,
		tbl1.EffectiveDate,
		getdate(),
		@UserID,
		0
		from #TempVendorOfferData tbl1
		inner join tb_UploadDestination tbl2 on tbl1.Destination = tbl2.Destination and tbl2.OfferID = @OfferID
		                                          and tbl1.EffectiveDate = tbl2.EffectiveDate
		inner join UC_Reference.dbo.tb_RateNumberIdentifier tbl3 on tbl2.RatingMethodID = tbl3.RatingMethodID
		inner join UC_Reference.dbo.tb_RateDimensionBand tbl4 on 
		                                    tbl3.RateDimension1BandID = tbl4.RateDimensionBandID
		                                and tbl1.RateTimeBand = tbl4.RateDimensionBand

		------------------
		-- Dialed Digits
		------------------

		insert into tb_UploadBreakout
		(
			OfferID,
			UploadDestinationID,
			DialedDigit,
			CountryCode,
			EffectiveDate,
			ModifiedDate,
			ModifiedByID,
			Flag
		)
		Select distinct
		@OfferID,
		tbl2.UploadDestinationID,
		tbl1.DialedDigit,
		tbl1.CountryCode,
		tbl1.EffectiveDate,
		getdate(),
		@UserID,
		0
		from #TempVendorOfferData tbl1
		inner join tb_UploadDestination tbl2 on tbl1.Destination = tbl2.Destination and tbl2.OfferID = @OfferID
														and tbl1.EffectiveDate = tbl2.EffectiveDate


End Try

Begin Catch

	Exec UC_Admin.dbo.SP_LogMessage NULL , @OfferLogFileName
	set @ErrorMsgStr = '	ERROR !!! During inserting records in database schema tables.'+ERROR_MESSAGE()
	Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName
	
    set @ProcessErrorFlag = 1

	GOTO PROCESSEND

End Catch


PROCESSEND:

----------------------------------------------------------------
-- Change the status of offer depending upon whether upload
-- was successful or failure
----------------------------------------------------------------

if (@ProcessErrorFlag = 1 )
Begin

		-------------------------------------------------------
		--  Change the status of offer to "Upload Failed"
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
			4 ,-- Upload Failed
			getdate(),
			@UserID
		)

		-------------------------------------
		-- Delete all the partially uploaded
		-- data from schema
		-------------------------------------

		Delete from tb_UploadRate
		where offerID = @OfferID

		Delete from tb_UploadBreakout
		where offerID = @OfferID

		Delete from tb_UploadDestination
		where offerID = @OfferID

End

Else
Begin


		-------------------------------------------------------
		--  Change the status of offer to "Upload Successful"
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
			3 ,-- Upload Successful
			getdate(),
			@UserID
		)

		--------------------------------------------
		-- Publish the statistics in the log file
		--------------------------------------------

		Declare @TotalDestinations int,
		        @TotalDialeddigits int,
				@TotalRate int


        Exec UC_Admin.dbo.SP_LogMessage NULL , @OfferLogFileName
		set @ErrorMsgStr = '	*******************************************************'
		Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName

		set @ErrorMsgStr = '	POST VALIDATION DETAILS :- '
		Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName

		set @ErrorMsgStr = '	*******************************************************'
		Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName


		select @TotalDestinations = count(distinct destination)
		from tb_UploadDestination
		where offerID = @OfferID

		select @TotalDialeddigits = count(*)
		from tb_UploadBreakout
        where offerID = @OfferID

		select @TotalRate = count(*)
		from tb_UploadRate
        where offerID = @OfferID

		set @ErrorMsgStr = '	Total Distinct Destinations Uploaded  :- ' + convert(varchar(20) , @TotalDestinations)
		Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName

		set @ErrorMsgStr = '	Total Distinct Rates Uploaded         :- ' + convert(varchar(20) , @TotalRate)
		Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName

		set @ErrorMsgStr = '	Total Distinct Dialed Digits Uploaded :- ' + convert(varchar(20) , @TotalDialeddigits)
		Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName


		set @ErrorMsgStr = '	*******************************************************'
		Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName

End

Return 0





GO
