USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSCreateCustomerOfferFileContent]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSCreateCustomerOfferFileContent]
(
	@SourceID int,
	@ExternalOfferFileName varchar(500),
	@OfferFileName varchar(500),
	@OfferDate DateTime,
	@OfferContent varchar(50),
	@UserID int,
	@OfferLogFileName varchar(1000) Output,
	@ResultFlag int Output,
	@ErrorDescription varchar(2000) Output
)
As

Declare @FileExists int,
		@cmd varchar(2000),
		@CustomerOfferLogDirectory varchar(1000),
		@SQLStr varchar(2000),
		@ErrorMsgStr varchar(2000),
		@ProcessErrorFlag int = 0,
		@OfferID int

Declare @ErrorDescription2 varchar(2000),
        @ResultFlag2 int

			

set @ResultFlag = 0
set @ErrorDescription = NULL

---------------------------------------------------------------
-- Check to see that the source ID exists in the system or not
---------------------------------------------------------------

if not exists ( select 1 from tb_Source where sourceID = @SourceID and SourceTypeID = -3 and flag = 0 )
Begin

	set @ErrorDescription = 'ERROR !!! Source ID : ' + convert(varchar(100) , @SourceID) + ' passed doesnot exist in the system'
	set @ResultFlag = 1
	set @ProcessErrorFlag = 1
	GOTO PROCESSEND

End

----------------------------------------------------
-- Validate the value of Offer Content being passed
----------------------------------------------------

if (@OfferContent is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! Offer Content type cannot be NULL'
	set @ResultFlag = 1
	set @ProcessErrorFlag = 1
	GOTO PROCESSEND

End

if (@OfferContent not in ('AZ' , 'PR' , 'FC') )
Begin

	set @ErrorDescription = 'ERROR !!! Value for Offer Content is not correct. Valid values are (AZ/FC/PR) '
	set @ResultFlag = 1
	set @ProcessErrorFlag = 1
	GOTO PROCESSEND

End


--------------------------------------------------------------
-- Extract the offer file name from the vendor offer
--------------------------------------------------------------

Declare @CompleteOfferFileName varchar(1000),
		@CustomerOfferWorkingDirectory varchar(1000)

--------------------------------------------------------
--Get the Vendor offer working directory to form the
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


--------------------------------------------------------
-- Form the complete offer file name and check if the 
-- file exists
--------------------------------------------------------

set @CompleteOfferFileName = @CustomerOfferWorkingDirectory + @OfferFileName

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
-- File upload is being Run
----------------------------------------------------

Exec UC_Admin.dbo.SP_LogMessage NULL , @OfferLogFileName
set @ErrorMsgStr = '==============================================================='
Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName

set @ErrorMsgStr = '****************** UPLOAD CUSTOMER OFFER FILE *****************'
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

create table #TempCustomerOfferData
(
	Destination varchar(500),
	EffectiveDate Date,
	Rate varchar(25),
	RatingMethod varchar(100),
	RateDimensionBand varchar(100)
)

create table #TempRecordCount ( DataRecord varchar(5000) )

Begin Try

	Select	@SQLStr = 'Bulk Insert  #TempCustomerOfferData '+ ' From ' 
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
	set  @ErrorMsgStr = '	ERROR !!! Bulk upload of customer offer file into database failed.' + ERROR_MESSAGE()
	Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName

    drop table #TempCustomerOfferData
	drop table #TempRecordCount
    
	set @ProcessErrorFlag = 1

	GOTO PROCESSEND

End Catch

if ( 
	(  select count(*)  from #TempRecordCount) <>
	(  select count(*)  from #TempCustomerOfferData )
   )
Begin 

	Exec UC_Admin.dbo.SP_LogMessage NULL , @OfferLogFileName
	set @ErrorMsgStr = '	ERROR !!! All records have not been exported into schema due to soem exception in format of one or more records'
	Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName

    drop table #TempCustomerOfferData
	drop table #TempRecordCount

    set @ProcessErrorFlag = 1

	GOTO PROCESSEND

End    

drop table #TempRecordCount

------------------------------------------------------
-- Alter the data table to add columns for:
-- ErrorMessage ,ErrorCode and Reference DestinationID
------------------------------------------------------

Alter table #TempCustomerOfferData add ReferenceDestinationID int
Alter table #TempCustomerOfferData add ErrorMessage varchar(2000)
Alter table #TempCustomerOfferData add ErrorCode varchar(20)


---------------------------------------------------------------
-- Validate the contents of the custmer offer to ensure that
-- all data is syntactically correct
---------------------------------------------------------------

Begin Try

        set @ResultFlag2 = 0
		set @ErrorDescription2 = NULL

		Exec SP_BSVerifyCustomerOfferContent @OfferLogFileName , @UserID, @ResultFlag2 Output , @ErrorDescription2 Output

End Try

Begin Catch

	Exec UC_Admin.dbo.SP_LogMessage NULL , @OfferLogFileName
	set @ErrorMsgStr = '	ERROR !!! During verification of customer offer content.' + ERROR_MESSAGE()
	Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName		

    set @ProcessErrorFlag = 1

	GOTO PROCESSEND

End Catch

if (@ResultFlag2 <> 0 )
Begin

	Exec UC_Admin.dbo.SP_LogMessage NULL , @OfferLogFileName
	set @ErrorMsgStr = '	' + @ErrorDescription2
	Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName	
	
	set @ErrorDescription = @ErrorDescription2	

    set @ProcessErrorFlag = 1

	GOTO PROCESSEND

End


if not exists ( select 1 from #TempCustomerOfferData where ErrorMessage is not NULL)
Begin

	set @ErrorMsgStr = '	INFO !!! Validation of records completed. No errors encountered.'
	Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName

End;


----------------------------------------------------------------------------
-- After offer content has been validated, add the Inbound numbering plan
-- destination id to the customer offer
----------------------------------------------------------------------------

With CTE_CustomerOfferAndReferenceDestinationMappingPerEffectiveDate
as
(
	Select tbl1.Destination , tbl2.DestinationID , tbl1.EffectiveDate , tbl3.DialedDigits
	from #TempCustomerOfferData tbl1
	inner join UC_Reference.dbo.tb_Destination tbl2 on tbl1.Destination = tbl2.Destination and tbl2.NumberplanID = -2
	inner join UC_Reference.dbo.tb_DialedDigits tbl3 on tbl2.DestinationID = tbl3.DestinationID
	Where tbl1.EffectiveDate between tbl2.BeginDate and isnull(tbl2.EndDate , tbl1.EffectiveDate)
	and  tbl1.EffectiveDate between tbl3.BeginDate and isnull(tbl3.EndDate , tbl1.EffectiveDate)
)
update tbl1
set tbl1.ReferenceDestinationID = tbl2.DestinationID
from #TempCustomerOfferData tbl1
inner join CTE_CustomerOfferAndReferenceDestinationMappingPerEffectiveDate tbl2
                        on tbl1.Destination = tbl2.Destination
						and
						   tbl1.EffectiveDate = tbl2.EffectiveDate

----------------------------------------------------------------------------
-- In case of Full Country and A-Z offers check to ensure that all
-- destinations for a country are being offered for a effective date
----------------------------------------------------------------------------

select @OfferContent as OfferContent

select * from #TempCustomerOfferData

if (@OfferContent not in ('AZ' , 'FC'))
	GOTO REGISTEROFFER

---------------------------------------------------------------
-- Validate the contents of the custmer offer to ensure that
-- all data is syntactically correct
---------------------------------------------------------------

Begin Try

        set @ResultFlag2 = 0
		set @ErrorDescription2 = NULL

		Exec SP_BSCheckMissingDestinationsforCustomerOffer @OfferContent , @OfferLogFileName , @ResultFlag2 Output , @ErrorDescription2 Output

End Try

Begin Catch

	Exec UC_Admin.dbo.SP_LogMessage NULL , @OfferLogFileName
	set @ErrorMsgStr = '	ERROR !!! During check for missing destinations in the customer offer.' + ERROR_MESSAGE()
	Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName		

    set @ProcessErrorFlag = 1

	GOTO PROCESSEND

End Catch

if (@ResultFlag2 <> 0 )
Begin

	Exec UC_Admin.dbo.SP_LogMessage NULL , @OfferLogFileName
	set @ErrorMsgStr = '	' + @ErrorDescription2
	Exec UC_Admin.dbo.SP_LogMessage @ErrorMsgStr , @OfferLogFileName	
	
    set @ProcessErrorFlag = 1

	GOTO PROCESSEND

End

REGISTEROFFER:

---------------------------------------------------------------------------
-- At this point, the contents of the offer have been validated and entries
-- can be created in the offer, destination , rate and break out tables
---------------------------------------------------------------------------

Begin Try

       ---------------------------------------------
	   -- Insert new record into tb_offer table
	   ---------------------------------------------

		Insert into tb_Offer
		(
			ExternalOfferFileName,
			OfferFileName,
			OfferDate,
			OfferTypeID,
			SourceID,
			OfferContent,
			ModifiedDate,
			ModifiedByID,
			Flag
		)
		values
		(
			@ExternalOfferFileName ,
			@OfferFileName,
			@OfferDate,
			-2,
			@SourceID,
			@OfferContent,
			getdate(),
			@UserID,
			0
		)

		set @OfferID  = @@IDENTITY

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
		ReferenceDestinationID,
		EffectiveDate,
		tbl2.RatingMethodID,
		NULL,
		Getdate(),
		@UserID,
		0
		from #TempCustomerOfferData tbl1
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
		from #TempCustomerOfferData tbl1
		inner join tb_UploadDestination tbl2 on tbl1.Destination = tbl2.Destination and tbl2.OfferID = @OfferID
		                                          and tbl1.EffectiveDate = tbl2.EffectiveDate
		inner join UC_Reference.dbo.tb_RateNumberIdentifier tbl3 on tbl2.RatingMethodID = tbl3.RatingMethodID
		inner join UC_Reference.dbo.tb_RateDimensionBand tbl4 on 
		                                    tbl3.RateDimension1BandID = tbl4.RateDimensionBandID
		                                and tbl1.RateDimensionBand = tbl4.RateDimensionBand ;

		---------------------------------------------------------------------
		-- Since Dialed Digits are not provided in the raw offer, we need to
		-- extract the dialed digits based on the Destination and Effective
		-- date
		---------------------------------------------------------------------

		With CTE_DDActiveOnRateSheetEffectiveDate
		as
		(
			Select tbl1.Destination , tbl1.EffectiveDate , tbl3.CountryCode , tbl4.DialedDigits
			from #TempCustomerOfferData tbl1
			inner join UC_Reference.dbo.tb_Destination tbl2 on tbl1.Destination = tbl2.Destination and tbl2.NumberplanID = -2
			inner join UC_Reference.dbo.tb_Country tbl3 on tbl2.CountryID = tbl3.CountryID
			inner join UC_Reference.dbo.tb_DialedDigits tbl4 on tbl2.DestinationID = tbl4.DestinationID
			Where tbl1.EffectiveDate between tbl2.BeginDate and isnull(tbl2.EndDate , tbl1.EffectiveDate)
			and tbl1.EffectiveDate between tbl4.BeginDate and isnull(tbl4.EndDate , tbl1.EffectiveDate)
		)
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
		tbl1.DialedDigits,
		tbl1.CountryCode,
		tbl1.EffectiveDate,
		getdate(),
		@UserID,
		0
		from CTE_DDActiveOnRateSheetEffectiveDate tbl1
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

        set @ResultFlag = 1
		set @ErrorDescription = @ErrorMsgStr
		-------------------------------------
		-- Delete all the partially uploaded
		-- data from schema
		-------------------------------------

		if (@OfferID is not NULL)
		Begin

				Delete from tb_UploadRate
				where offerID = @OfferID

				Delete from tb_UploadBreakout
				where offerID = @OfferID

				Delete from tb_UploadDestination
				where offerID = @OfferID

				Delete from tb_Offer
				where offerID = @OfferID

		End

End

Else
Begin


		-------------------------------------------------------
		--  Change the status of offer to "Created"
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
			14 ,-- Created
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
