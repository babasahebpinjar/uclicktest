USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_ValidateVendorOfferContent]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_ValidateVendorOfferContent]
(
   @VendorOfferID int,
   @RunModeFlag int,
   @UserID int,
   @ResultFlag int output,
   @ErrorDescription varchar(2000) output
)
--With Encryption
As

Declare @ReferenceID int,
        @OfferType varchar(20),
		@OfferTypeID int,
        @ErrorMsgStr varchar(2000),
        @OfferStatus varchar(200),
		@OfferStatusID int,
        @OfferDate datetime,
		@OfferLogFileName varchar(500),
        @TotalOffers int,
        @OfferFolderType  varchar(20),
        @NameOfVendorOfferToValidate varchar(1000),
		@NameOfVendorOfferToValidateOutput varchar(1000),
		@ParseFileName varchar(1000),
        @VendorOfferDirectory varchar(500),
        @ReferenceFolderName  varchar(100),
        @DateFolderName varchar(50),
        @OfferFileName varchar(500),
        @cmd varchar(2000),
		@FileExists int,
		@SQLStr varchar(5000),
		@ProcessErrorFlag int,
		@OfferUpdateStatus varchar(20),
		@UpdatedOfferstatusID int = 0

set @ProcessErrorFlag = 0
set @ResultFlag = 0

-----------------------------------------------------------------
-- Validate all the input parammeters to make sure no exception 
-- value is passed.
-----------------------------------------------------------------

if ( @VendorOfferID is NULL )
Begin

     set @ErrorDescription = 'ERROR !!!! Please pass a valid VendorOfferID. NULL value not accepted. '
     set @ResultFlag = 1
     Return


End

if ( @RunModeFlag is NULL )
Begin

      set @ErrorDescription = 'ERROR !!!! Please pass a valid value for Run Mode ( Test - 0/ Real - 1). NULL value not accepted.'
      set @ResultFlag = 1
      Return

End

if ( @RunModeFlag not in (0,1) )
Begin

     set @ErrorDescription = 'ERROR !!!! Please pass a valid value for Run Mode ( Test - 0/ Real - 1).'
     set @ResultFlag = 1
     Return

End

-------------------------------------------------
-- Get the default rating method and Rate Band
-------------------------------------------------

Declare @DefaultRatingMethod varchar(60),
        @DefaultRateBand varchar(60),
		@DefaultRateTypeID int

select @DefaultRatingMethod = ConfigValue
from Tb_Config
where ConfigName = 'DefaultRatingMethod'

select @DefaultRateBand = ConfigValue
from Tb_Config
where ConfigName = 'DefaultRateBand'


if ( ( @DefaultRatingMethod is NULL ) or (@DefaultRateBand is NULL ) )
Begin

       set @ErrorDescription = 'Error!!! One or both Configuration parameters "DEFAULTRATINGMETHOD/DEFAULTRATEBAND" are not defined'
       set @ResultFlag = 1
       set @ProcessErrorFlag = 1
       GOTO PROCESSEND

End

if not exists ( select 1 from VW_RatingMethodInfo where rtrim(ltrim(RatingMethod)) = rtrim(ltrim(@DefaultRatingMethod)) )
Begin

       set @ErrorDescription = 'Error!!! The DEFAULTRATINGMETHOD : (' + @DefaultRatingMethod + ') does not exist in the system'
       set @ResultFlag = 1
       set @ProcessErrorFlag = 1
       GOTO PROCESSEND

End

if not exists ( 
					select 1 from VW_RatingMethodInfo 
					where rtrim(ltrim(RatingMethod)) = rtrim(ltrim(@DefaultRatingMethod)) 
					and  rtrim(ltrim(RateDimensionBand)) = rtrim(ltrim(@DefaultRateBand))
			  )
Begin

       set @ErrorDescription = 'Error!!! The DEFAULTRATINGMETHOD : (' + @DefaultRatingMethod + ') is not associated with the DEFAULTRATEBAND : (' + @DefaultRateBand + ')'
       set @ResultFlag = 1
       set @ProcessErrorFlag = 1
       GOTO PROCESSEND

End

--------------------------------------------------
-- Fetch the default rate type id to be populated
-- in all the records
--------------------------------------------------

select @DefaultRateTypeID = RateItemID
from VW_RatingMethodInfo
where rtrim(ltrim(RatingMethod)) = rtrim(ltrim(@DefaultRatingMethod))
and  rtrim(ltrim(RateDimensionBand)) = rtrim(ltrim(@DefaultRateBand))


--------------------------------------------------------------
-- Check if the passed VendorOfferID belongs to a valid offer
-- in the system.
--------------------------------------------------------------

if  not exists ( select 1 from tb_vendorofferdetails where vendorofferid = @VendorOfferID  )
Begin

     set @ErrorDescription = 'ERROR !!!! No vendor offer exists in the system for the VendorOfferId :'+ convert(varchar(10) , @VendorOfferID )
     set @ResultFlag = 1
     set @ProcessErrorFlag = 1
     GOTO PROCESSEND

End

---------------------------------------------
-- Get the referenceid used to register the 
-- offer in system   
---------------------------------------------

Select @ReferenceID =  referenceid,
       @OfferType = offertype,
       @OfferTypeID = OfferTypeID,
       @OfferStatus = offerstatus,
       @OfferStatusID = offerStatusID,
       @OfferDate = offerreceivedate,
       @OfferFileName = offerfilename
from TB_VendorOfferDetails
where VendorOfferID = @VendorOfferID

if ( ( @ReferenceID is null ) or ( @OfferTypeID is null ) or (@OfferStatusID is NULL ) )
Begin

     set @ErrorDescription = 'Either one of the parameters REFERENCEID/OFFERTYPEID/OFFERSTATUSID is either NULL or not a valid value'
     set @ResultFlag = 1
     set @ProcessErrorFlag = 1
     GOTO PROCESSEND

End

if not exists ( select 1 from tb_offerstatusworkflow where FromVendorOfferStatusID = @OfferStatusID and ToVendorOfferStatusID= 2 ) -- Does valid transition exist from current state to VALIDATING
Begin

     set @ErrorDescription = 'There does not exist a workflow transition from ' + @OfferStatus + ' status to Validating status'
     set @ResultFlag = 1
     set @ProcessErrorFlag = 1
     GOTO PROCESSEND

End

if ( @OfferFileName is null )
Begin

     set @ErrorDescription = 'No Vendor offer file exists under the VendorOfferID : ' + convert(varchar(10) , @VendorOfferID )
     set @ResultFlag = 1
     set @ProcessErrorFlag = 1
     GOTO PROCESSEND

End


-----------------------------------------------------------------
-- Get the Reference No and other attributes for the ReferenceID
-----------------------------------------------------------------

Declare @ReferenceNo varchar(50),
        @ParseTemplateName varchar(50),
	@MultipleSheetsInOffer int

select @ReferenceNo = ReferenceNo,
       @ParseTemplateName = ParseTemplateName,
       @MultipleSheetsInOffer = MultipleSheetsInOffer
from tb_vendorreferencedetails
where referenceid = @ReferenceID

if ( @MultipleSheetsInOffer is null )
Begin

     set @ErrorDescription = 'ERROR !!! Reference Detail related to number of sheets to process in an offer file ( MultipleSheetsInOffer ) is missing'
     set @ResultFlag = 1
     set @ProcessErrorFlag = 1
     GOTO PROCESSEND

End

-------------------------------------------------------------------------------
--Changes Added on 10-Sept-2012
--The change has been added to ensure that the offer contents are validated against the
-- latest instance of rates in the system. When validating the offer, there should be
-- no other offer in the system, which may change the data in downstream system
-------------------------------------------------------------------------------

if exists ( 
		select 1 from tb_vendorofferdetails 
		where referenceid = @ReferenceID
		and offerreceivedate <= @OfferDate
		and offerstatusid in (1,2,3,4,5,6,10) --('Registered' , 'Validated' , 'Process Error' , 'Upload Error' , 'Validation Rejected' , 'Processing' )
		and vendorofferid <> @VendorOfferID
	  )
Begin  

	    set @ErrorDescription = 'ALERT!!! Cannot Validate offer with offer id : (' +convert(varchar(20) , @VendorOfferID)  +'). There are offers pending Validation or upload into the system with offer date less than the offer date for current offer'
	    set @ResultFlag = 1
	    Return
End



------------------------------------------------------------------------
-- Formulate the name of the Vendor Offer File, that has to be loaded 
-- into the interconnect system.
------------------------------------------------------------------------

-----------------------------------------------------------------
-- STEP 1:
-- Get the VendorOfferDirectory config value from config table
------------------------------------------------------------------

Select @VendorOfferDirectory = ConfigValue
from TB_Config
where Configname = 'VendorOfferDirectory'

if ( @VendorOfferDirectory is NULL )
Begin

       set @ErrorDescription = 'Error!!! Vendor Offer Directory configuration is not defined'
       set @ResultFlag = 1
       set @ProcessErrorFlag = 1
       GOTO PROCESSEND

End

if ( RIGHT(@VendorOfferDirectory , 1) <> '\' )
     set @VendorOfferDirectory = @VendorOfferDirectory + '\'


create table #tempCommandoutput
(
  CommandOutput varchar(500)
)

set @cmd = 'dir ' + '"' + @VendorOfferDirectory + '"' + '/b'
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
       set @ErrorDescription = 'Error!!! Vendor Offer Directory ' + @VendorOfferDirectory + ' does not exist or is invalid'
       set @ResultFlag = 1
       Drop table #tempCommandoutput
       set @ProcessErrorFlag = 1
       GOTO PROCESSEND
End

-----------------------------------------------------------------
-- STEP 2:
-- Build the name of the folder for offer from the ReferenceNo
-- and the offer content.
------------------------------------------------------------------

set @ReferenceFolderName = replace(@ReferenceNo , '/' , '_') + '_' + @OfferType

-----------------------------------------------------------------
-- STEP 3:
-- Build the name of the datefolder for offer from the offer
-- receive date.
------------------------------------------------------------------

select @DateFolderName = 
	  convert(varchar(2) , day(@OfferDate) ) +
	  case month(@OfferDate)
		  when 1 then 'Jan'
		  when 2 then 'Feb'
		  when 3 then 'Mar'
		  when 4 then 'Apr'
		  when 5 then 'May'
		  when 6 then 'Jun'
		  when 7 then 'Jul'
		  when 8 then 'Aug'
		  when 9 then 'Sep'
		  when 10 then 'Oct'
		  when 11 then 'Nov'
		  when 12 then 'Dec'
	  end +
	  convert(varchar(4) , year(@OfferDate)) 


-------------------------------------------------------
-- Combine all the attributes from above steps to
-- build the complete name of the offer file.
-------------------------------------------------------

set @NameOfVendorOfferToValidate  =  @VendorOfferDirectory + @DateFolderName + '\' + @ReferenceFolderName + '\' + @OfferFileName  
set @OfferLogFileName = @VendorOfferDirectory + @DateFolderName + '\' + @ReferenceFolderName + '\' + 'VendorOffer('+ convert(varchar(20) , @VendorOfferID) + ')_ProcessDetails.Log'

--------------------------------------------------
-- Delete any previous instance of the log file, 
-- as this is a fresh run.
--------------------------------------------------

set @FileExists = 0

Exec master..xp_fileexist @OfferLogFileName , @FileExists output  

if ( @FileExists = 1 )
Begin

   set @cmd = 'del ' + '"' + @OfferLogFileName + '"'
   Exec master..xp_cmdshell @cmd

End 

------------------------------------------------------------------------
-- Check that the extension of the vendor offer file registered in the
-- system belongs to the allowed extension list.
------------------------------------------------------------------------

Declare @RegisterdOfferExtension varchar(50),
        @ListOfAllowedExtensions varchar(2000),
        @FileExtension varchar(15)

set @RegisterdOfferExtension = reverse(substring( reverse(@OfferFileName) , 1 ,charindex('.' , reverse(@OfferFileName)) ))

select @ListOfAllowedExtensions = ConfigValue
from tb_config
where configname = 'AllowedVendorOfferExtensions'

if ( @ListOfAllowedExtensions is NULL )
Begin

       set @ErrorDescription = 'Error!!! List of Allowed Vendor Offer Extensions (AllowedVendorOfferExtensions) configuration is not defined'
       set @ResultFlag = 1
       set @ProcessErrorFlag = 1
       GOTO PROCESSEND

End

-------------------------------------
-- MOVE OFFER INTO VALIDATING STATE
-------------------------------------

select @OfferUpdateStatus = offerstatus
from tb_offerstatus
where offerstatusid = 2

Update tb_vendorofferdetails
set offerstatus = @OfferUpdateStatus,
    offerstatusid = 2,
    modifieddate = getdate(),
    modifiedbyID = @UserID
where vendorofferid = @VendorOfferID

set @UpdatedOfferstatusID = 2 -- Offer moved to validating state

create table #TempAllowedOfferExtensions ( FileExtension varchar(20) )

while ( charindex('|' , @ListOfAllowedExtensions ) <> 0)
Begin

	set @FileExtension = substring( @ListOfAllowedExtensions , 1 , charindex('|' , @ListOfAllowedExtensions ) - 1 )

	insert into #TempAllowedOfferExtensions values (@FileExtension)

	set @ListOfAllowedExtensions = substring( @ListOfAllowedExtensions , charindex('|' , @ListOfAllowedExtensions ) + 1 , Len(@ListOfAllowedExtensions) )

End

set @FileExtension = substring( @ListOfAllowedExtensions , 1 , Len(@ListOfAllowedExtensions) )

insert into #TempAllowedOfferExtensions values (@FileExtension)

if not exists ( select 1 from #TempAllowedOfferExtensions where FileExtension = @RegisterdOfferExtension )
Begin

	Exec SP_LogMessage NULL , @OfferLogFileName
	set @ErrorMsgStr = '	ERROR !!! Extension : (' + @RegisterdOfferExtension + ') of the registered vendor offer file : ( '+ @OfferFileName +') not is list of allowed extensions'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	Exec SP_LogMessage NULL , @OfferLogFileName
	set @ErrorMsgStr = '	INFO !!! Allowed Extension List is : (' + @ListOfAllowedExtensions + ')'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorDescription =  'ERROR !!! Extension : (' + @RegisterdOfferExtension + ') of the vendor offer file : ( '+ @OfferFileName +') not in list of allowed extensions.'+
				 'Allowed Extension List is : (' + @ListOfAllowedExtensions + ')'

	set @ResultFlag = 1

    Drop table #TempAllowedOfferExtensions

    set @ProcessErrorFlag = 1

	GOTO PROCESSEND

End

Drop table #TempAllowedOfferExtensions

----------------------------------------------
-- Get the name of the parsing template file
----------------------------------------------

Declare @ParseConfigDirectory  varchar(500)

select @ParseConfigDirectory = ConfigValue
from TB_Config
where Configname = 'ParseConfigDirectory'

if ( @ParseConfigDirectory is NULL )
Begin

        set @ErrorDescription = 'Error!!! Parse Config Directory configuration is not defined'
        set @ResultFlag = 1

	Exec SP_LogMessage NULL , @OfferLogFileName
	set @ErrorMsgStr = '	ERROR !!! Parse Config Directory configuration is not defined'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorDescription = 'ERROR !!! Parse Config Directory configuration is not defined'
	set @ResultFlag = 1

        set @ProcessErrorFlag = 1

	GOTO PROCESSEND

End

if ( RIGHT(@ParseConfigDirectory , 1) <> '\' )
     set @ParseConfigDirectory = @ParseConfigDirectory + '\'


set @cmd = 'dir ' + '"' + @ParseConfigDirectory + '"' + '/b'
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

	Exec SP_LogMessage NULL , @OfferLogFileName
	set @ErrorMsgStr = '	ERROR !!! Config directory for parsing template ' + @ParseConfigDirectory + ' does not exist or is invalid'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName
        Drop table #tempCommandoutput

	set @ErrorDescription = 'ERROR !!! Config directory for parsing template ' + @ParseConfigDirectory + ' does not exist or is invalid'
	set @ResultFlag = 1

        set @ProcessErrorFlag = 1

	GOTO PROCESSEND

End

drop table #tempCommandoutput

-------------------------------------------------------
-- Build the name of the parsing config file and check
-- if the same exists or not.
-------------------------------------------------------

set @ParseFileName = @ParseConfigDirectory + @ParseTemplateName + '.Fmt'

set @FileExists = 0

Exec master..xp_fileexist @ParseFileName , @FileExists output  

if ( @FileExists <> 1 )
Begin

	Exec SP_LogMessage NULL , @OfferLogFileName
	set @ErrorMsgStr = '	ERROR !!! Parsing Format File : ' + @ParseTemplateName + '.Fmt' + ' does not exists in the Parsing Config Directory : '+ @ParseConfigDirectory
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorDescription = 'ERROR !!! Parsing Format File : ' + @ParseTemplateName + '.Fmt' + ' does not exists in the Parsing Config Directory : '+ @ParseConfigDirectory
	set @ResultFlag = 1

        set @ProcessErrorFlag = 1

	GOTO PROCESSEND

End 

-------------------------------------------------------
-- Get the default folder for the Perl executable
-------------------------------------------------------

Declare @PerlExecutable varchar(500)

select @PerlExecutable = ConfigValue
from tb_config
where configname = 'PerlExecutable'

--------------------------------------------------------
-- Get the name of the executable to be used for parsing,
-- depending on the whether the offer is multi or single
-- sheet
--------------------------------------------------------

Declare @ExecFileName varchar(500)

select @ExecFileName = tbl1.ConfigValue
from TB_Config tbl1
where tbl1.Configname =
     Case
         When ( @MultipleSheetsInOffer = 0 and @RegisterdOfferExtension = '.xls' ) then 'ParseSingleSheetVendorOfferExcel'
	 When ( @MultipleSheetsInOffer = 1 and @RegisterdOfferExtension = '.xls' ) then 'ParseMultipleSheetVendorOfferExcel'
         When ( @MultipleSheetsInOffer = 0 and @RegisterdOfferExtension = '.xlsx' ) then 'ParseSingleSheetVendorOfferXLX'
	 When ( @MultipleSheetsInOffer = 1 and @RegisterdOfferExtension = '.xlsx' ) then 'ParseMultipleSheetVendorOfferXLX'
         When ( @MultipleSheetsInOffer = 0 and @RegisterdOfferExtension = '.slk' ) then 'ParseSingleSheetVendorOfferSLK'
	 When ( @MultipleSheetsInOffer = 0 and @RegisterdOfferExtension = '.csv' ) then 'ParseSingleSheetVendorOfferCSV'
	 Else 'INVALID'
     End


if ( @ExecFileName is NULL )
Begin

	Exec SP_LogMessage NULL , @OfferLogFileName
	set @ErrorMsgStr = '	ERROR !!! Configuration for executable to parse vendor sheets ( ParseSingleSheetVendorOfferExcel/ParseMultipleSheetVendorOfferExcel/ParseSingleSheetVendorOfferXLX/ParseMultipleSheetVendorOfferXLX/ParseSingleSheetVendorOfferSLK/ParseSingleSheetVendorOfferCSV) are missing'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorDescription = 'ERROR !!! Configuration for executable to parse vendor sheets are missing'
	set @ResultFlag = 1

        set @ProcessErrorFlag = 1

	GOTO PROCESSEND

End

set @FileExists = 0

Exec master..xp_fileexist @ExecFileName , @FileExists output  

if ( @FileExists <> 1 )
Begin

	Exec SP_LogMessage NULL , @OfferLogFileName
	set @ErrorMsgStr = '	ERROR !!! Executable for parsing vendor sheet : ' + @ExecFileName + ' does not exist'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorDescription = 'ERROR !!! Executable for parsing vendor sheet : ' + @ExecFileName + ' does not exist'
	set @ResultFlag = 1

        set @ProcessErrorFlag = 1

	GOTO PROCESSEND


End 

------------------------------------------------------
-- Publish all the information to check its validity
------------------------------------------------------

--print 'Vendor Offer File        : ' + @NameOfVendorOfferToValidate
--print 'Log File Name            : ' + @OfferLogFileName
--print 'Parsed Offer Name        : ' + @NameOfVendorOfferToValidateOutput
--print 'Parsing Config File Name : ' + @ParseFileName
--print 'Executable Name          : ' + @ExecFileName

select 'Executable Name          : ' + @ExecFileName

------------------------------------------------------
-- Execute the command to parse the vendor offer file
-----------------------------------------------------

set @NameOfVendorOfferToValidateOutput  =  @VendorOfferDirectory + @DateFolderName + '\' + @ReferenceFolderName + '\' + replace(@OfferFileName , @RegisterdOfferExtension , '.Parsed')

-----------------------------------------------------
-- Remove any special characters like single quote
-- from the name of the parsed file being created
-----------------------------------------------------

set @NameOfVendorOfferToValidateOutput = replace(@NameOfVendorOfferToValidateOutput , '''' , '')

if (@PerlExecutable is not NULL)
Begin

			set @cmd = 'ECHO ? && '+'"'+@PerlExecutable+'"' + ' ' + '"' + @ExecFileName + '"' + ' ' + 
			           '"' +  @NameOfVendorOfferToValidate + '"' + ' ' + 
					   '"' + @ParseFileName + '"' + ' ' + 
					   '"' + @NameOfVendorOfferToValidateOutput + '"' + ' ' +
					   '"' + @OfferLogFileName + '"'

End

Else
Begin

			set @cmd = 'perl ' + '"' + @ExecFileName + '"' + ' ' + 
			           '"' +  @NameOfVendorOfferToValidate + '"' + ' ' + 
					   '"' + @ParseFileName + '"' + ' ' + 
					   '"' + @NameOfVendorOfferToValidateOutput + '"' + ' ' +
					   '"' + @OfferLogFileName + '"'

End

--print @cmd

Exec master..xp_cmdshell @cmd

------------------------------------------------------
-- Post exectuion check if the parsed file exists or 
-- not
-----------------------------------------------------

set @FileExists = 0

Exec master..xp_fileexist @NameOfVendorOfferToValidateOutput , @FileExists output  

if ( @FileExists <> 1 )
Begin

        set @ErrorDescription = 'Error !!! Exception during parsing, as parsed file : ' + replace(@OfferFileName , @RegisterdOfferExtension , '.Parsed') + ' does not exist'
	set @ResultFlag = 1

        set @ProcessErrorFlag = 1

		
	GOTO PROCESSEND

End 


---------------------------------------------------------
-- Load the parsed offer into database to perfrom the 
-- essential validation checks.
---------------------------------------------------------

Declare @RowTerminator varchar(10),
        @FieldTerminator varchar(10)

set @RowTerminator = '\n'
set @FieldTerminator = '|'

create table #TempVendorOfferData
(
	Destination varchar(500),
	DialedDigit varchar(60),
	EffectiveDateStr varchar(20),
	Rate varchar(25),
	BusinessIndicator varchar(1000)
)


create table #TempRecordCount ( DataRecord varchar(5000) )

Begin Try

	Select	@SQLStr = 'Bulk Insert  #TempVendorOfferData '+ ' From ' 
				  + '''' + @NameOfVendorOfferToValidateOutput +'''' + ' WITH (
				  FIELDTERMINATOR  = ''' + @FieldTerminator + ''','+
			  'ROWTERMINATOR    = ''' + @RowTerminator + ''''+')'

	--print @SQLStr
	Exec (@SQLStr)

	--------------------------------------------------------
	-- Buld upload records into Temp table to make sure
	-- all records have been uploaded
	--------------------------------------------------------

	Select	@SQLStr = 'Bulk Insert  #TempRecordCount '+ ' From ' 
				  + '''' + @NameOfVendorOfferToValidateOutput +'''' + ' WITH ( '+				 
			  'MAXERRORS = 0,ROWTERMINATOR    = ''' + @RowTerminator + ''''+')'

	--print @SQLStr
	Exec (@SQLStr)

End Try

Begin Catch

	Exec SP_LogMessage NULL , @OfferLogFileName
	set @ErrorMsgStr = '	ERROR !!! Format of upload Vendor Offer File not correct or has been changed from last upload.'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	Exec SP_LogMessage NULL , @OfferLogFileName
	set @ErrorMsgStr = '	ERROR!!! Vendor offer has not been parsed correctly. Cannot proceed with next validation steps'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorDescription = 'ERROR!!! Vendor offer has not been parsed correctly. Cannot proceed with next validation steps'
	set @ResultFlag = 1

    drop table #TempVendorOfferData

	drop table #TempRecordCount

    set @ProcessErrorFlag = 1

	GOTO PROCESSEND

End Catch

select count(*)  from #TempRecordCount
select count(*)  from #TempVendorOfferData


if ( 
	(  select count(*)  from #TempRecordCount) <>
	(  select count(*)  from #TempVendorOfferData )
   )
Begin 

	Exec SP_LogMessage NULL , @OfferLogFileName
	set @ErrorMsgStr = '	ERROR !!! Format of upload Vendor Offer File not correct or has been changed from last upload.'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	Exec SP_LogMessage NULL , @OfferLogFileName
	set @ErrorMsgStr = '	ERROR!!! Vendor offer has not been parsed correctly. Cannot proceed with next validation steps'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	drop table #TempVendorOfferData
	drop table #TempRecordCount

    set @ProcessErrorFlag = 1

	GOTO PROCESSEND

End    

drop table #TempRecordCount

select *
from #TempVendorOfferData 

---------------------------------------------------
-- Once the data has been exported into database,
-- the parsed file can be removed.
----------------------------------------------------

set @cmd = 'del ' + '"' + @NameOfVendorOfferToValidateOutput + '"'
Exec master..xp_cmdshell @cmd

------------------------------------------------------
-- Alter the data table to add columns for:
-- CountryCode , ErrorMessage ,ErrorCode,
-- RatingMethod , RateBand , RateTypeID
------------------------------------------------------

Alter table #TempVendorOfferData add CountryCode varchar(20)
Alter table #TempVendorOfferData add ErrorMessage varchar(2000)
Alter table #TempVendorOfferData add ErrorCode varchar(20)
Alter table #TempVendorOfferData add EffectiveDate DateTime
Alter table #TempVendorOfferData add RatingMethod varchar(60)
Alter table #TempVendorOfferData add RateBand varchar(60)
Alter table #TempVendorOfferData add RateTypeID int

------------------------------------------------------------------------------
-- Check to make sure that all the records imported into the system, have a 
-- proper date value for effective date column
------------------------------------------------------------------------------

update #TempVendorOfferData
set EffectiveDate = 
	Case
		When isdate(isnull(EffectiveDateStr , '0')) = 1 then convert(datetime ,EffectiveDateStr)
		Else convert(datetime ,'12/31/1899')
	End

-----------------------------------------------------------------------
-- Get the default rating method, rate band and Rate Type ID 
-- to update the records
-----------------------------------------------------------------------

update #TempVendorOfferData
set RatingMethod = rtrim(ltrim(@DefaultRatingMethod)),
    RateBand = rtrim(ltrim(@DefaultRateBand)),
    RateTypeID = @DefaultRateTypeID

-------------------------------------------------------
-- Update the Country Code for all the exported records
-------------------------------------------------------

Declare @TempCountryCodeStr varchar(60),
        @VarCountryCode varchar(20),
	@ListOfCountriesToSkip varchar(1000),
        @CountryCode varchar(15)

select @ListOfCountriesToSkip = ConfigValue
from tb_config
where configname = 'SkipCountryCodes'

create table #TempAllCountryCode ( CountryCode varchar(20) )

while ( charindex('|' , @ListOfCountriesToSkip ) <> 0)
Begin

	set @CountryCode = substring( @ListOfCountriesToSkip , 1 , charindex('|' , @ListOfCountriesToSkip ) - 1 )

	if ( isnumeric(@CountryCode) = 1 )
	Begin

		insert into #TempAllCountryCode values (@CountryCode)

	End

	set @ListOfCountriesToSkip = substring( @ListOfCountriesToSkip , charindex('|' , @ListOfCountriesToSkip ) + 1 , Len(@ListOfCountriesToSkip) )

End

set @CountryCode = substring( @ListOfCountriesToSkip , 1 , Len(@ListOfCountriesToSkip) )

if ( isnumeric(@CountryCode) = 1 )
Begin

	insert into #TempAllCountryCode values (@CountryCode)

End

Declare GetAllCountryCode_Cur Cursor For
select countrycode
from vw_country

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


update #TempVendorOfferData
set CountryCode = 'NOT EXIST'

---------------------------------------------------------
-- Added check to ensure that any '0' or '00' is removed 
-- from front of the dial digit
--------------------------------------------------------

Update #TempVendorOfferData
set DialedDigit = substring(Dialeddigit ,3,len(DialedDigit))
where substring(Dialeddigit ,1,2) = '00'

---------------------------------------------------------
-- Added check to ensure that any '+' is removed 
-- from front of the dial digit
--------------------------------------------------------

Update #TempVendorOfferData
set DialedDigit = substring(Dialeddigit ,2,len(DialedDigit))
where substring(Dialeddigit ,1,1) = '+'

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

-------------------------------------------------------------------
-- Call the procedure to perform the Pre Validation Rules
-- for each specific source.
-------------------------------------------------------------------

if exists ( select 1 from tb_ValidationRules where referenceid = @ReferenceID and validationstatusid = 1)
Begin

	Declare @ResultFlagCustomValidation int = 0,
	        @ErrorDescriptionCustomValidation varchar(2000)


	Exec  SP_CustomValidationChecks @VendorOfferID , @OfferLogFileName , @ResultFlagCustomValidation Output , @ErrorDescriptionCustomValidation Output

	if ( @ResultFlagCustomValidation = 1 )
	Begin

		set @ResultFlag = 1
		set @ErrorDescription = @ErrorDescriptionCustomValidation
		GOTO PROCESSEND

	End


End

select distinct destination , countrycode
from #TempVendorOfferData

-----------------------------------------------------------------
-- Make sure that there are no records missing the rating method,
-- RateBand and RateType
-----------------------------------------------------------------
-- It could be possible that there are TOD records and custom 
-- rules might have been used for population of TOD rating Method
-- and rate bands
-----------------------------------------------------------------

if exists ( Select 1 from #TempVendorOfferData where  (RatingMethod is NULL ) or (RateBand is NULL) )
Begin

		set @ResultFlag = 1
		set @ErrorDescription = '	ERROR!!! There are records for which the Rating Method or Rate Band is not populated'
		Exec SP_LogMessage @ErrorDescription , @OfferLogFileName
		set @ProcessErrorFlag = 1
		GOTO PROCESSEND

End


if exists (
				select 1
				from 
				( select distinct RatingMethod , RateBand from #TempVendorOfferData ) tbl1
				left join VW_RatingMethodInfo tbl2 on tbl1.RatingMethod = tbl2.RatingMethod 
												   and tbl1.RateBand = tbl2.RateDimensionBand
				where tbl2.RatingMethod is NULL
		  )
Begin

		set @ResultFlag = 1
		set @ErrorDescription = '	ERROR!!! There are records for which the Rating Method or Rate Band do not exist in the system'
		Exec SP_LogMessage @ErrorDescription , @OfferLogFileName
		set @ProcessErrorFlag = 1
		GOTO PROCESSEND


End

----------------------------------------------------------------------
-- Re-populate the RATE TYPEID for all the records, because the
-- RateBand and RatingMethod might have changed in the custom
-- validation 
----------------------------------------------------------------------

update tbl1
set tbl1.RateTypeID = tbl2.RateItemID
from #TempVendorOfferData tbl1
inner join VW_RatingMethodInfo tbl2 on
       ltrim(rtrim(tbl1.RatingMethod)) =  ltrim(rtrim(tbl2.RatingMethod))
	   and ltrim(rtrim(tbl1.RateBand)) =  ltrim(rtrim(tbl2.RateDimensionBand))


-----------------------------------------------------------------
-- Call the procedure to perform the general validation on the 
-- contents.
-----------------------------------------------------------------

Declare @ReturnFlag int,
        @ErrorDescription2 varchar(2000)

Exec @ReturnFlag = SP_GenericOfferValidationChecks @VendorOfferID , @OfferLogFileName, @UserID , @ReturnFlag Output , @ErrorDescription2 Output

-----------------------------------------------------
-- If the return flag is not 0, it means that the 
-- offer has been rejected in the validation stage.
-----------------------------------------------------

if ( @ReturnFlag = 1 )
Begin

        set @ResultFlag = 1
        set @ErrorDescription = @ErrorDescription2
	GOTO PROCESSEND

End

---------------------------------------------------------------
-- Proceed for creation of the output file, which will  be
-- passed to the executable for building final excel file for
-- upload.
---------------------------------------------------------------

Declare @QualifiedTableName varchar(50),
        @OutputTableName varchar(50),
        @ValidatedOutputFileName varchar(500)

set @ValidatedOutputFileName = @VendorOfferDirectory + @DateFolderName + '\' + @ReferenceFolderName + '\' + replace(@OfferFileName , @RegisterdOfferExtension , '.Validated')
set @OutputTableName = 'TB_VendorOffer_'+ convert(varchar(20), @VendorOfferID)
Set @QualifiedTableName = db_name() + '.dbo.' + @OutputTableName

if exists ( select 1 from sysobjects where name = @OutputTableName and xtype = 'U' )
	Exec('Drop table ' + @OutputTableName )

Exec ('select * into ' + @OutputTableName + ' from #TempVendorOfferData')

SET @cmd = 'bcp "SELECT Destination , DialedDigit , convert(varchar(20) ,EffectiveDate , 101) , Rate , RatingMethod , RateBand from ' + @QualifiedTableName + ' order by Destination ' +'" queryout ' + '"' + ltrim(rtrim(@ValidatedOutputFileName)) + '"' + ' -c -t "|" -r"\n" -T -S '+ @@servername
--print @cmd 

exec master..xp_cmdshell @cmd

set @FileExists = 0

Exec master..xp_fileexist @ValidatedOutputFileName , @FileExists output  

if ( @FileExists <> 1 )
Begin

	Exec SP_LogMessage NULL , @OfferLogFileName
	set @ErrorMsgStr = '	ERROR !!! Unable to create the output file : ' + @ValidatedOutputFileName + ' post validation'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorDescription = 'ERROR !!! Unable to create the output file : ' + @ValidatedOutputFileName + ' post validation'
	set @ResultFlag = 1

        set @ProcessErrorFlag = 1

	GOTO PROCESSEND

End 

-------------------------------------------------------
-- Call the executable to write the final upload
-- excel file.
-------------------------------------------------------

Declare @UploadExcelFileName varchar(500)

select @ExecFileName = tbl1.ConfigValue
from TB_Config tbl1
where tbl1.Configname = 'CreateExcelVendorOffer'

------------------------------------------------------
-- Added this code to handle the References which have
-- Multi DD records in an output file
------------------------------------------------------
-- Change : 16 April 2015
--------------------------
-- START CHANGE
--------------------------

-----------------------------------------------------------------
-- Check if there are more than 65,535 records in the Validated
-- output file and reference does not exist in the Exception
-- table
-----------------------------------------------------------------

Declare @TotalValidatedOutputRec int

select @TotalValidatedOutputRec = count(*)
from #TempVendorOfferData


if ( ( @TotalValidatedOutputRec > 65535 ) and not exists (select 1 from tb_ExceptionReferenceList where referenceID = @ReferenceID) )
Begin

	Exec SP_LogMessage NULL , @OfferLogFileName
	set @ErrorMsgStr = '	ERROR !!! More than 65,535 unique records exist for the offer file. Need to handle as Exception Reference.'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

        set @ProcessErrorFlag = 1

	GOTO PROCESSEND

End 

if exists ( select 1 from tb_ExceptionReferenceList where referenceID = @ReferenceID )
Begin

	select @ExecFileName = tbl1.ConfigValue
	from TB_Config tbl1
	where tbl1.Configname = 'CreateExcelVendorOfferMultiDD'

End


--------------------------
-- END CHANGE
--------------------------
    

if ( @ExecFileName is NULL )
Begin

	Exec SP_LogMessage NULL , @OfferLogFileName
	set @ErrorMsgStr = '	ERROR !!! Configuration for executable to build the final vendor offer upload excel file ( CreateExcelVendorOffer )'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorDescription = 'ERROR !!! Configuration for executable to build the final vendor offer upload excel file ( CreateExcelVendorOffer )'
	set @ResultFlag = 1

        set @ProcessErrorFlag = 1

	GOTO PROCESSEND

End

set @FileExists = 0

Exec master..xp_fileexist @ExecFileName , @FileExists output  

if ( @FileExists <> 1 )
Begin

	Exec SP_LogMessage NULL , @OfferLogFileName
	set @ErrorMsgStr = '	ERROR !!! Executable to build the final vendor offer upload excel file : ' + @ExecFileName + ' does not exist'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorDescription = 'ERROR !!! Executable to build the final vendor offer upload excel file : ' + @ExecFileName + ' does not exist'
	set @ResultFlag = 1

        set @ProcessErrorFlag = 1

	GOTO PROCESSEND

End 

drop table #TempVendorOfferData

---------------------------------------------------------
-- Execute the command to create the final upload excel
-- file
---------------------------------------------------------

set @UploadExcelFileName = @VendorOfferDirectory + @DateFolderName + '\' + @ReferenceFolderName + '\' + replace(@OfferFileName , @RegisterdOfferExtension , '_Ver1.xls')

if (@PerlExecutable is not NULL )
Begin

		set @cmd = 'ECHO ? && '+'"'+@PerlExecutable+'"' + ' ' + '"' + @ExecFileName + '"' + ' ' + 
		           '"' +  @ValidatedOutputFileName + '"' + ' '  + 
				   '"' + @UploadExcelFileName + '"' + ' ' + 
				   '"' + @OfferLogFileName + '"'

End

Else
Begin

		set @cmd = 'perl ' + '"' + @ExecFileName + '"' + ' ' + 
		           '"' +  @ValidatedOutputFileName + '"' + ' '  + 
				   '"' + @UploadExcelFileName + '"' + ' ' + 
				   '"' + @OfferLogFileName + '"'

End

--print @cmd

Exec master..xp_cmdshell @cmd

------------------------------------------------------
-- Post exectuion check if the parsed file exists or 
-- not
-----------------------------------------------------

set @FileExists = 0

Exec master..xp_fileexist @UploadExcelFileName , @FileExists output  

if ( @FileExists <> 1 )
Begin

	Exec SP_LogMessage NULL , @OfferLogFileName
	set @ErrorMsgStr = '	ERROR !!! Exception during creation of final upload excel file : ' + @UploadExcelFileName + '. File does not exist'
	Exec SP_LogMessage @ErrorMsgStr , @OfferLogFileName

	set @ErrorDescription = 'ERROR !!! Exception during creation of final upload excel file : ' + @UploadExcelFileName + '. File does not exist'
	set @ResultFlag = 1

        set @ProcessErrorFlag = 1

	GOTO PROCESSEND

End 

PROCESSEND:

if ( @ProcessErrorFlag = 1 )
Begin

	if exists ( select 1 from tb_offerstatusworkflow where FromVendorOfferStatusID in ( @OfferStatusID , @UpdatedOfferstatusID ) and ToVendorOfferStatusID= 5)
	Begin

		select @OfferUpdateStatus = offerstatus
		from tb_offerstatus where offerstatusid = 5

		Update tb_vendorofferdetails
		set offerstatus = @OfferUpdateStatus,
		    offerstatusid = 5,
		    modifiedDate = getdate(),
		    ModifiedByID = @UserID
		where vendorofferid = @VendorOfferID

	End

End

Else
Begin

	Update tb_vendorofferdetails
	set ValidatedOfferFileName = replace(@OfferFileName , @RegisterdOfferExtension , '_Ver1.xls')
	where vendorofferid = @VendorOfferID

End

--------------------------------------------------------------------------
-- ********************* EMAIL SECTION FOR VALIDATION ********************
--------------------------------------------------------------------------
-- START SECTION
------------------------

Declare @MessageStr varchar(2000),
        @EmailAddress Varchar(2000),
		@SubjectLine Varchar(2000),
		@Attachment varchar(1000),
		@Account varchar(100)


Select @Account = Account
From TB_VendorReferenceDetails
where ReferenceID = @ReferenceID

select @EmailAddress = ConfigValue
from tb_config
where configname = 'ValidateOfferAlertEmailAddress'

------------------------------------------------------------------------
-- Prepare the Message String with preliminary information for offer
------------------------------------------------------------------------

set @MessageStr = '======================================================' + '<br>' +
                  '					<b> VENDOR OFFER INFO </b>			 ' + '<br>' +
				  '======================================================' + '<br>' +
				  '<b>Account         :</b> ' + @Account  + '<br>'+
                  '<b>Reference       :</b> ' + @ReferenceNo + '<br>'+                  
                  '<b>Offer Type      :</b> ' + @OfferType + '<br>'+  
				  '<b>Offer Date      :</b> ' + convert(varchar(30) , @OfferDate, 100) +'<br>' +
				  '======================================================' + '<br>' + '<br>'

if ( @ProcessErrorFlag = 1 )
Begin

	     set @MessageStr = @MessageStr +  '<b>PROCESS ERROR : </b>'+
	                       '<br><br'+
			       '<b>' + @ErrorDescription + ' </b>'+
			       '<br><br>'
					

	     if ( @RunModeFlag = 0 )
         Begin

			set @SubjectLine = 'OFFER VALIDATION : PROCESS ERROR : TEST MODE : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID)

	     End

	     Else
	     Begin

			set @SubjectLine = 'OFFER VALIDATION : PROCESS ERROR : REAL MODE : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID)

	     End


End

Else
Begin

	if exists ( select 1 from tb_vendorofferdetails where vendorofferid = @VendorOfferID and offerstatusid = 4  ) -- Validation Rejected
	Begin

		     set @MessageStr = @MessageStr +'<b>OFFER REJECTED : </b>'+
					'<br><br>'+
				        '<b> Vendor offer has failed one or more validation checks, and has been rejected </b>'+
					'<br><br>'
									

		     if ( @RunModeFlag = 0 )
		     Begin

				set @SubjectLine = 'OFFER VALIDATION : REJECT : TEST MODE : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID)

		     End

		     Else
		     Begin

				set @SubjectLine = 'OFFER VALIDATION : REJECT : REAL MODE : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID)

		     End


	End

	if exists ( select 1 from tb_vendorofferdetails where vendorofferid = @VendorOfferID and offerstatusid = 3  ) -- Validated
	Begin

		     set @MessageStr =  @MessageStr + '<b>OFFER VALIDATED : </b>' + 
					'<br><br>' +
					'<b> Vendor offer has completed validation, and is ready for upload </b>'+
					'<br><br>'


		     if ( @RunModeFlag = 0 )
		     Begin

				set @SubjectLine = 'OFFER VALIDATION : SUCCESS : TEST MODE : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID)

		     End

		     Else
		     Begin

				set @SubjectLine = 'OFFER VALIDATION : SUCCESS : REAL MODE : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID)

		     End

	End


End

set @Attachment = @OfferLogFileName

if (@EmailAddress is not null)
Begin

    --select @EmailAddress, @SubjectLine, @MessageStr, @Attachment
	Exec SP_SendEmailAlerts @EmailAddress, @SubjectLine, @MessageStr , @Attachment

End

-----------------------
-- END SECTION
-----------------------
------------------------------------------------------------------
-- If the validation is being run in Test Mode only, then reverse
--  the offer to its original state
------------------------------------------------------------------

if ( @RunModeFlag = 0 )
Begin

	Update tb_vendorofferdetails
	set offerstatus = @OfferStatus ,
	    offerstatusid = @OfferStatusID,
	    ModifiedDate = getdate(),
	    ModifiedByID = @UserID
	where vendorofferid = @VendorOfferID

        ------------------------------------------------------
	-- Change added by Pushpinder 02/12/2012
	-- Commented previous update section
	-- This change allows the user to view on the interface
	-- post test mode validation, all the details pertaining 
	-- to upload type , log file and validated offer file
	-------------------------------------------------------

	--Update tb_vendorofferdetails
	--set offerstatus = @OfferUpdateStatus ,
	  --  offerstatusid = 1,
	   -- UploadOfferType = NULL , 
	    --PartialOfferProcessFlag = NULL,
	    --ValidatedOfferFileName  = NULL
	--where vendorofferid = @VendorOfferID

End

if exists ( select 1 from sysobjects where name = @OutputTableName and xtype = 'U' )
	Exec('Drop table ' + @OutputTableName )
GO
