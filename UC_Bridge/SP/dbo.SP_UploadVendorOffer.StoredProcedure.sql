USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UploadVendorOffer]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_UploadVendorOffer]
(
   @VendorOfferID int,
   @PublishEmailFlag int,
   @UserID int,
   @ErrorDescription varchar(2000) Output,
   @ResultFlag int Output
)
--WITH ENCRYPTION
As

Declare @ReferenceID int,
        @OfferType varchar(20),
        @ErrorMsgStr varchar(2000),
        @OfferStatus varchar(200),
        @OfferDate datetime,
        @TotalOffers int,
        @OfferFolderType  varchar(20),
        @NameOfVendorOfferToUpload varchar(1000),
        @VendorOfferDirectory varchar(500),
        @ReferenceFolderName  varchar(100),
        @DateFolderName varchar(50),
        @OfferFileName varchar(500),
        @cmd varchar(2000),
        @MaxInstanceNumber int,
		@FileExists int,
		@UploadOfferType varchar(20),
		@OfferUpdateStatus varchar(200)

set @ResultFlag = 0
set @ErrorDescription = NULL

-----------------------------------------------------------
-- Define parameters for pushing email regarding progress
-----------------------------------------------------------

Declare @EmailAddress Varchar(2000),
	@SubjectLine Varchar(2000),
	@MessageStr varchar(5000)

select @EmailAddress = ConfigValue
from tb_config
where configname = 'UploadOfferAlertEmailAddress'

create table #tempCommandoutput
(
  CommandOutput varchar(500)
)

-----------------------------------------------------------------
-- Validate all the input parammeters to make sure no exception 
-- value is passed.
-----------------------------------------------------------------

if ( @VendorOfferID is NULL )
Begin

     set @ErrorMsgStr = 'ERROR !!!! Please pass a valid VendorOfferID. NULL value not accepted. '
     set @PublishEmailFlag = 1

     set @MessageStr = '<b>PARAMETER ERROR </b>' + '<br><br>' +
					 '<b>' + @ErrorMsgStr + ' </b>'

     set @SubjectLine = 'OFFER UPLOAD INITITATE : PARAMETER ERROR : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID)

	 set @ResultFlag = 1

     GOTO PUBLISHMAIL

End

if ( @PublishEmailFlag is NULL ) 
Begin

     set @ErrorMsgStr = 'ERROR !!!! Please pass a valid value for Publish Email Flag.NULL value not accepted. '
     set @PublishEmailFlag = 1

     set @MessageStr = '<b>PARAMETER ERROR </b>' + '<br><br>' +
					 '<b>' + @ErrorMsgStr + ' </b>'

     set @SubjectLine = 'OFFER UPLOAD INITITATE : PARAMETER ERROR : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID)

	 set @ResultFlag = 1

     GOTO PUBLISHMAIL

End

else
Begin

	if ( ( @PublishEmailFlag > 1 ) or ( @PublishEmailFlag < 0 ))
	Begin

		     set @ErrorMsgStr = 'ERROR !!!! Please pass a valid value for Publish Email Flag.Accepted values are (0/1). '
		     set @PublishEmailFlag = 1

		     set @MessageStr = '<b>PARAMETER ERROR </b>' + '<br><br>' +
							 '<b>' + @ErrorMsgStr + ' </b>'

		     set @SubjectLine = 'OFFER UPLOAD INITITATE : PARAMETER ERROR : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID)

			 set @ResultFlag = 1

		     GOTO PUBLISHMAIL

	End

End

--------------------------------------------------------------
-- Check if the passed VendorOfferID belongs to a valid offer
-- in the system.
--------------------------------------------------------------

if  not exists ( select 1 from tb_vendorofferdetails where vendorofferid = @VendorOfferID  )
Begin

     set @ErrorMsgStr = 'ERROR !!!! No vendor offer exists in the system for the VendorOfferId :'+ convert(varchar(10) , @VendorOfferID )

     RaisError('%s' , 16,1 , @ErrorMsgStr )

     set @MessageStr = '<b>REFERENCE DATA ERROR </b>' + '<br><br>' +
					 '<b>' + @ErrorMsgStr + ' </b>'

     set @SubjectLine = 'OFFER UPLOAD INITITATE : REFERENCE DATA ERROR : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID)

	 set @ResultFlag = 1

     GOTO PUBLISHMAIL

End

---------------------------------------------
-- Get the referenceid used to register the 
-- offer in system   
---------------------------------------------

Declare @OfferTypeID int,
        @UploadOffertypeID int,
		@OfferStatusID int

Select @ReferenceID =  referenceid,
       @OfferType = offertype,
	   @OfferTypeID = offerTypeID,
       @UploadOfferType = UploadOfferType,
	   @UploadOffertypeID = UploadOfferTypeID,
       @OfferStatus = offerstatus,
	   @OfferStatusID = OfferStatusID,
       @OfferDate = offerreceivedate,
       @OfferFileName = Validatedofferfilename
from TB_VendorOfferDetails
where VendorOfferID = @VendorOfferID

if ( ( @ReferenceID is null ) or ( @OfferTypeID is null ) or ( @OfferTypeID not in (1,2,3) ) or (@OfferStatusID is NULL ) )
Begin

     set @ErrorMsgStr = 'Either one of the parameters REFERENCEID/OFFERTYPE/OFFERSTATUS is NULL or not a valid value'
     RaisError('%s' , 16,1 , @ErrorMsgStr )

     set @MessageStr = '<b>REFERENCE DATA ERROR </b>' + '<br><br>' +
					 '<b>' + @ErrorMsgStr + ' </b>'

     set @SubjectLine = 'OFFER UPLOAD INITITATE : REFERENCE DATA ERROR : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID)

	 set @ResultFlag = 1

     GOTO PUBLISHMAIL

End

if ( @OfferStatusID <> 3 )
Begin

     if ( @OfferStatus is NULL )
	 Begin
			select @OfferStatus = offerstatus
			from tb_OfferStatus
			where OfferStatusID = @OfferStatusID

	 End

     set @ErrorMsgStr = 'The Vendor Offer is not in VALIDATED State. The offer status is : '+ @OfferStatus + '. Offer has to be in VALIDATED status to initiate upload.' 
     RaisError('%s' , 16,1 , @ErrorMsgStr )

     set @MessageStr = '<b>REFERENCE DATA ERROR </b>' + '<br><br>' +
					 '<b>' + @ErrorMsgStr + ' </b>'

     set @SubjectLine = 'OFFER UPLOAD INITITATE : REFERENCE DATA ERROR : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID)

	 set @ResultFlag = 1

     GOTO PUBLISHMAIL

End

if ( @OfferFileName is null )
Begin

     set @ErrorMsgStr = 'No Vendor offer file exists VALIDATED under the VendorOfferID : ' + convert(varchar(10) , @VendorOfferID )
     RaisError('%s' , 16,1 , @ErrorMsgStr )

     set @MessageStr = '<b>REFERENCE DATA ERROR </b>' + '<br><br>' +
					 '<b>' + @ErrorMsgStr + ' </b>'

     set @SubjectLine = 'OFFER UPLOAD INITITATE : REFERENCE DATA ERROR : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID)

	 set @ResultFlag = 1

     GOTO PUBLISHMAIL

End

if ( ( @UploadOfferTypeID is null ) or ( @UploadOfferTypeID not in (1,2,3 ) )  )
Begin

     set @ErrorMsgStr = 'Parameter UPLOADOFFERTYPE is either NULL or not a valid value'
     RaisError('%s' , 16,1 , @ErrorMsgStr )

     set @MessageStr = '<b>REFERENCE DATA ERROR </b>' + '<br><br>' +
					 '<b>' + @ErrorMsgStr + ' </b>'
     set @SubjectLine = 'OFFER UPLOAD INITITATE : REFERENCE DATA ERROR : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID)

	 set @ResultFlag = 1

     GOTO PUBLISHMAIL

End

Declare @ReferenceNo varchar(100),
        @VendorSourceid int,
        @OfferTemplateID int ,
        @VendorValueSourceid int,
	@AutoOfferUploadFlag int

Select @ReferenceNo = Referenceno,
       @VendorSourceid = VendorSourceid,
       @OfferTemplateID =  OfferTemplateID,
       @VendorValueSourceid = VendorValueSourceid,
       @AutoOfferUploadFlag = AutoOfferUploadFlag
from TB_VendorReferenceDetails
where ReferenceID = @ReferenceID

------------------------------------------------------------------------
-- Formulate the name of the Vendor Offer File, that has to be loaded 
-- into the uCLICK system.
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

	     set @ErrorMsgStr = 'Error!!! Vendor Offer Directory configuration is not defined'
	     RaisError('%s' , 16,1 , @ErrorMsgStr )

	     set @MessageStr = '<b>REFERENCE DATA ERROR </b>' + '<br><br>' +
						 '<b>' + @ErrorMsgStr + ' </b>'
	     set @SubjectLine = 'OFFER UPLOAD INITITATE : REFERENCE DATA ERROR : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID)

		 set @ResultFlag = 1

	     GOTO PUBLISHMAIL

End

if ( RIGHT(@VendorOfferDirectory , 1) <> '\' )
     set @VendorOfferDirectory = @VendorOfferDirectory + '\'



set @cmd = 'dir ' + '"' + @VendorOfferDirectory + '"' + '/b'
print @cmd

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
	    set @ErrorMsgStr = 'Error!!! Vendor Offer Directory ' + @VendorOfferDirectory + ' does not exist or is invalid'
	     RaisError('%s' , 16,1 , @ErrorMsgStr )

	     set @MessageStr = '<b>REFERENCE DATA ERROR </b>' + '<br><br>' +
						 '<b>' + @ErrorMsgStr + ' </b>'

	     set @SubjectLine = 'OFFER UPLOAD INITITATE : REFERENCE DATA ERROR : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID)

		 set @ResultFlag = 1

	     GOTO PUBLISHMAIL

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

--------------------------------------------------------
-- Check the directory for the vendor file, having the
--  the appropriate version.

-- The file with the highest version number will be 
-- classified for upload.
--------------------------------------------------------

set @VendorOfferDirectory = @VendorOfferDirectory + @DateFolderName  

---------------------------------------------------------------
-- Check that the directory and the vendor offer files exist 
---------------------------------------------------------------

delete from #tempCommandoutput

set @cmd = 'dir ' + '"' + @VendorOfferDirectory + '"' + '/b'
print @cmd

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
	     set @ErrorMsgStr = 'Error!!! Folder for Date : ' + @DateFolderName + ' does not exist or is invalid'
	     RaisError('%s' , 16,1 , @ErrorMsgStr )

	     set @MessageStr = '<b>REFERENCE DATA ERROR </b>' + '<br><br>' +
						 '<b>' + @ErrorMsgStr + ' </b>'
	     set @SubjectLine = 'OFFER UPLOAD INITITATE : REFERENCE DATA ERROR : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID)

		 set @ResultFlag = 1

	     GOTO PUBLISHMAIL

End



delete from #tempCommandoutput
where CommandOutput is NULL 


select @ReferenceFolderName = LTRIM(rtrim(CommandOutput))
from #tempCommandoutput
where CHARINDEX(@ReferenceFolderName ,CommandOutput) <> 0 

delete from #tempCommandoutput

set @VendorOfferDirectory = @VendorOfferDirectory + '\' + @ReferenceFolderName

set @cmd = 'dir ' + '"' + @VendorOfferDirectory + '"' + '/b'
print @cmd

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

	     set @ErrorMsgStr = 'Error!!! Reference Folder : ' + @ReferenceFolderName + ' does not exist or is invalid for date : ' + @DateFolderName
	     RaisError('%s' , 16,1 , @ErrorMsgStr )

	     set @MessageStr = '<b>REFERENCE DATA ERROR </b>' + '<br><br>' +
						 '<b>' + @ErrorMsgStr + ' </b>'
	     set @SubjectLine = 'OFFER UPLOAD INITITATE : REFERENCE DATA ERROR : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID)

		 set @ResultFlag = 1

	     GOTO PUBLISHMAIL

End	

-------------------------------------------------------
-- Combine all the attributes from above steps to
-- build the complete name of the offer file.
-------------------------------------------------------

set @NameOfVendorOfferToUpload  =  @VendorOfferDirectory  + '\' + @OfferFileName  

-------------------------------------------------------------------------------
--Changes Added on 10-Sept-2012
--The change has been added to ensure that no offer gets loaded in the system,
--if there exists an offer with an offer date less than the offer date of
--the offer being uploaded.
-------------------------------------------------------------------------------

if exists ( 
		select 1 from tb_vendorofferdetails 
		where referenceid = @ReferenceID
		and offerreceivedate <= @OfferDate
		--and offerstatus in ('Registered' , 'Validated' , 'Process Error' , 'Upload Error' , 'Validation Rejected' )
		and offerstatusID in (1 , 2 , 3 , 4 ,5 , 6 ,10)
		and vendorofferid <> @VendorOfferID
	  )
Begin  

	    if ( @AutoOfferUploadFlag = 1 )
	    Begin

	           set @PublishEmailFlag = 0

	    End

	    Else
	    Begin

		    set @ErrorMsgStr = 'Error!!! Cannot upload offer. There are offers pending upload into the system with offer date less than the offer date for current offer'
		    print @ErrorMsgStr

		     set @MessageStr = '<b>INFO </b>' + '<br><br>' +
							 '<b>' + @ErrorMsgStr + ' </b>' 

		     set @SubjectLine = 'OFFER UPLOAD INITITATE : INFO : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID)

	    End

		set @ResultFlag = 1

        GOTO PUBLISHMAIL
End



------------------------------------------------------------
-- Check the OverrideContentFlag to determine if the default
-- registered offer content or the passed offer content type 
-- has to be used for offer processing.
------------------------------------------------------------

if ( @UploadOfferType is NULL )
Begin

		select @UploadOfferType = Code
		from tblOfferType
		where ID = @OfferTypeID


End

set @OfferType = @UploadOfferType

-----------------------------------------------------------------
-- Call the SP_BSRegisterOffer Procedure to register the offer
-- for upload for all the call types.
-----------------------------------------------------------------

Declare @ErrorDescription2 varchar(2000),
        @ResultFlag2 int = 0,
		@ReturnOfferID int,
		@RandomIDValue varchar(200)

Begin Try


     --Exec BIServer.UC_Commerce.dbo.SP_BSRegisterOffer @VendorSourceid , @NameOfVendorOfferToUpload , @OfferType ,
	    --                                               -1 , @OfferDate , @UserID , @ReturnOfferID Output , @ResultFlag2 Output,
					--								   @ErrorDescription2 Output

     Exec Referenceserver.UC_Commerce.dbo.SP_BSRegisterOffer @VendorSourceid , @NameOfVendorOfferToUpload , @OfferType ,
	                                                   -1 , @OfferDate , @UserID , @ReturnOfferID Output , @ResultFlag2 Output,
													   @ErrorDescription2 Output



End Try

Begin Catch

	     set @ErrorMsgStr = 'Error !!! Calling procedure SP_BSRegisterOffer for loading the MAIN offer for vendor offer file : '+ @OfferFileName + ' with vendor offer ID : ' + convert(varchar(10) , @VendorOfferID) + '.' + ERROR_MESSAGE()
	     RaisError('%s' , 16,1 , @ErrorMsgStr )

	     set @MessageStr = '<b>PROCESS ERROR </b>' + '<br><br>' +
						 '<b>' + @ErrorMsgStr + ' </b>'

	     set @SubjectLine = 'OFFER UPLOAD INITITATE : PROCESS ERROR : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID)

		 set @ResultFlag = 1

	     GOTO PUBLISHMAIL

End Catch

if (@ResultFlag2 <> 0 )
Begin

	     set @ErrorMsgStr = 'Error !!! Calling procedure SP_BSRegisterOffer for loading the MAIN offer for vendor offer file : '+ @OfferFileName + ' with vendor offer ID : ' + convert(varchar(10) , @VendorOfferID) + '.' + @ErrorDescription2

	     set @MessageStr = '<b>PROCESS ERROR </b>' + '<br><br>' +
						 '<b>' + @ErrorMsgStr + ' </b>'
	     set @SubjectLine = 'OFFER UPLOAD INITITATE : PROCESS ERROR : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID)

		 set @ResultFlag = 1

	     GOTO PUBLISHMAIL

End 

Else
Begin

	set @RandomIDValue = convert(varchar(20) , @ReturnOfferID)

End


if ( @VendorValueSourceid is not NULL )
Begin

	Begin Try

			set @ResultFlag2 = 0
			set @ErrorDescription2 = NULL

			 --Exec BIServer.UC_Commerce.dbo.SP_BSRegisterOffer @VendorSourceid , @NameOfVendorOfferToUpload , @OfferType ,
				--                                               -1 , @OfferDate , @UserID , @ReturnOfferID Output , @ResultFlag2 Output,
							--								   @ErrorDescription Output

			 Exec ReferenceServer.UC_Commerce.dbo.SP_BSRegisterOffer @VendorValueSourceid , @NameOfVendorOfferToUpload , @OfferType ,
													-1 , @OfferDate , -1 , @ReturnOfferID Output, @ResultFlag2 Output,
													@ErrorDescription Output

	End Try

	Begin Catch

		     set @ErrorMsgStr = 'Error !!! Calling the SP_BSRegisterOffer procedure for loading the secondary offer for vendor offer file : '+ @OfferFileName + ' with vendor offer ID : ' + convert(varchar(10) , @VendorOfferID) + '.' + ERROR_MESSAGE()
		     RaisError('%s' , 16,1 , @ErrorMsgStr )

		     set @MessageStr = '<b>PROCESS ERROR </b>' + '<br><br>' +
							 '<b>' + @ErrorMsgStr + ' </b>'
		     set @SubjectLine = 'OFFER UPLOAD INITITATE : PROCESS ERROR : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID)

			 set @ResultFlag = 1

		     GOTO PUBLISHMAIL


	End Catch

	if (@ResultFlag2 <> 0 )
	Begin

			 set @ErrorMsgStr = 'Error !!! Calling procedure SP_BSRegisterOffer for loading the Secondary offer for vendor offer file : '+ @OfferFileName + ' with vendor offer ID : ' + convert(varchar(10) , @VendorOfferID) + '.' + @ErrorDescription2

			 set @MessageStr = ' <b>PROCESS ERROR </b>' + '<br><br>' +
							 '<b>' + @ErrorMsgStr + ' </b>'

			 set @SubjectLine = 'OFFER UPLOAD INITITATE : PROCESS ERROR : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID)

			 set @ResultFlag = 1

			 GOTO PUBLISHMAIL

	End 

	Else
	Begin

		set @RandomIDValue = @RandomIDValue + '|' + convert(varchar(20) , @ReturnOfferID)

	End


End

------------------------------------------------------------------
-- At this stage, offer upload has been initiated successfully
------------------------------------------------------------------

set @ErrorMsgStr = 'SUCCESS : Offer Upload process initiated for vendor offer ID : ' + convert(varchar(10) , @VendorOfferID)

set @MessageStr = ' <b>' + @ErrorMsgStr + ' </b>'
set @SubjectLine = 'OFFER UPLOAD INITITATE : SUCCESS : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID)


PUBLISHMAIL:

if ( @ResultFlag = 1)
Begin

		set @ErrorDescription = @ErrorMsgStr

End

Else
Begin

		-------------------------------------------------------------
		-- Update the status of the Vendor offer to Processing
		-------------------------------------------------------------

		select @OfferUpdateStatus = Offerstatus
		from tb_OfferStatus
		where OfferStatusID = 6 -- Processing

		Update tb_vendorofferdetails
		set offerstatus = @OfferUpdateStatus,
			offerstatusid = 6,
			modifieddate = getdate(),
			modifiedbyID = @UserID
		where vendorofferid = @VendorOfferID

		-------------------------------------------------------------------------------
		-- Check the AutoResetReferenceToDefault config and depending on the
		-- value, set the configuration of Rate Increase and Check New Destination 
		-- to default value
		-------------------------------------------------------------------------------

		Declare @AutoResetReferenceToDefault int,
		        @DefaultValueRateIncreaseCheck int,
				@DefaultValueCheckNewDestination int

		select @AutoResetReferenceToDefault = ConfigValue
		from tb_Config
		where Configname = 'AutoResetReferenceToDefault'

		if (@AutoResetReferenceToDefault is NULL) 
			set @AutoResetReferenceToDefault = 0

		if (@AutoResetReferenceToDefault = 1)
		Begin

				select @DefaultValueRateIncreaseCheck = ConfigValue
				from tb_Config
				where Configname = 'DefaultValueRateIncreaseCheck'

				select @DefaultValueCheckNewDestination = ConfigValue
				from tb_Config
				where Configname = 'DefaultValueCheckNewDestination'

				if (@DefaultValueRateIncreaseCheck is NULL) 
					set @DefaultValueRateIncreaseCheck = 0

				if (@DefaultValueCheckNewDestination is NULL) 
					set @DefaultValueCheckNewDestination = 1

                ---------------------------------------------------------
				-- Update the Validation flags to the default values
				--------------------------------------------------------- 

				update TB_VendorReferenceDetails
				set SkipRateIncreaseCheck = @DefaultValueRateIncreaseCheck,
				    CheckNewDestination = @DefaultValueCheckNewDestination
                where ReferenceID = @ReferenceID
				

		End

		 
		--------------------------------------------------------------
		-- Add the Random ID Values to the Vendor offer detail table,
		-- to make sure that we are able to trace the correct offer,
		-- in a scenario where there exist duplicate offers by the
		-- same file name.
		--------------------------------------------------------------

		update tb_vendorofferdetails
		set RandomIDValue = @RandomIDValue
		where vendorofferid = @VendorOfferID

End

if ( @PublishEmailFlag = 1 )
Begin

	if ( @EmailAddress is not null )
	Begin

		Exec SP_SendEmailAlerts @EmailAddress, @SubjectLine, @MessageStr , NULL

	End

End

drop table #tempCommandoutput
GO
