USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_SetVendorOfferProcessStatus]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_SetVendorOfferProcessStatus]
(
   @VendorOfferID int,
   @UserID int,
   @ErrorDescription varchar(2000) Output,
   @ResultFlag int Output
)
--With Encryption
As

Declare @DefaultVendorUploadDir varchar(500),
        @ErrorMsgStr varchar(2000),
        @cmd varchar(4000),
        @VendorOfferDate datetime,
        @VendorOfferDirectory varchar(500),
        @VendorOfferStatusID int,
        @VendorReferenceNo varchar(100),
        @FileExists int,
        @VendorFileName varchar(500),
	    @AbsoluteVendorFileName varchar(500),
	    @VendorOfferTypeID int,
		@VendorOfferType varchar(100),
	    @VendorSourceID int,
        @VendorValueSourceID int ,
	    @UploadFileName varchar(200),
        @OfferName varchar(200),
        @Command varchar(4000),
        @UploadOfferProcessDate datetime,
        @RegistryStatusID int,
		@EmailAddress Varchar(2000),
        @SubjectLine Varchar(2000),
		@LoadExcelFileName varchar(1000),
		@LoadOfferName varchar(200),
		@Attachment varchar(5000),
		@PartialOfferProcessFlag int,
		@UploadOfferTypeID int,
		@RandomIDValue varchar(100),
		@RandomIDMainOffer int,
		@RandomIDValueOffer int

set @ResultFlag = 0
set @ErrorDescription = NULL

--------------------------------------------------------
-- Get all Vendor Offer Specific details and attributes
--------------------------------------------------------

select @VendorOfferDate = tbl1.offerreceivedate,
       @VendorOfferStatusID = tbl1.offerstatusID,
       @VendorReferenceNo = tbl2.ReferenceNo,
       @VendorFileName = tbl1.ValidatedOfferFileName,
       @VendorOfferTypeID = tbl1.OfferTypeID,
	   @VendorOfferType = tbl1.OfferType,
       @UploadOfferTypeID = tbl1.UploadOfferTypeID,
       @VendorSourceID = tbl2.VendorSourceid,
       @VendorValueSourceID  =  tbl2.VendorValueSourceid,
       @PartialOfferProcessFlag = PartialOfferProcessFlag,
       @RandomIDValue = RandomIDValue
from tb_vendorofferdetails tbl1  
inner join TB_VendorReferenceDetails tbl2 on tbl1.Referenceid = tbl2.ReferenceID
where VendorOfferID =  @VendorOfferID 

select @DefaultVendorUploadDir = configvalue
from TB_Config
where configname = 'VendorOfferDirectory'

if ( @DefaultVendorUploadDir is NULL )
Begin

    set @ErrorDescription = 'ERROR !!!!! Default Vendor Offer Upload Directory not configured in variable VendorOfferDirectory' 
	set @ErrorMsgStr = '<b>VALIDATION ERROR:</b>' + '<br><br>'+
					 '<b>ERROR !!!!! Default Vendor Offer Upload Directory not configured in variable VendorOfferDirectory.</b>'

	set @SubjectLine = 'OFFER UPLOAD STATUS : ERROR : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID) + ' for Reference : '+ @VendorReferenceNo

	set @ResultFlag = 1

	GOTO PUBLISHEMAIL

End


if ( RIGHT(@DefaultVendorUploadDir, 1) <> '\' )
	set @DefaultVendorUploadDir = @DefaultVendorUploadDir + '\'

---------------------------------------------------------
-- Check if the default vendor directory defined is valid
-- or not.
----------------------------------------------------------

create table #tempCommandoutput
(
  CommandOutput varchar(500)
)

set @cmd = 'dir ' + '"' + @DefaultVendorUploadDir + '"' + '/b'

insert into #tempCommandoutput
Exec master..xp_cmdshell @cmd
	

if exists ( 
		select 1 from #tempCommandoutput where CommandOutput in
		( 
		  'The system cannot find the file specified.' ,
		  'The system cannot find the path specified.',
		  'The network path was not found.'
		 )
	 )
Begin  
        set @ErrorDescription = 'ERROR!!! Default Vendor Offer Directory ' + @DefaultVendorUploadDir + ' does not exist or is invalid'
		set @ErrorMsgStr = '<b>VALIDATION ERROR:</b>' + '<br><br>'+
					 '<b>ERROR!!! Default Vendor Offer Directory ' + @DefaultVendorUploadDir + ' does not exist or is invalid.</b>'

		set @SubjectLine = 'OFFER UPLOAD STATUS : ERROR : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID) + ' for Reference : '+ @VendorReferenceNo

       Drop table #tempCommandoutput

       set @ResultFlag = 1

       GOTO PUBLISHEMAIL

End


---------------------------------------------------
-- Check if the Vendor offer is in Registered state.
-- In case it is not, then throw error.
---------------------------------------------------   

if ( @VendorOfferStatusID <> 6) -- Processing status
Begin  

    set @ErrorDescription = 'ERROR!!! Vendor Offer with ID ' + convert(varchar(20) , @VendorOfferID) + ' either does not exist or is not in PROCESSING status'

	set @ErrorMsgStr = '<b>VALIDATION ERROR:</b>' + '<br><br>'+
					 '<b>ERROR!!! Vendor Offer with ID ' + convert(varchar(20) , @VendorOfferID) + ' either does not exist or is not in PROCESSING status</b>'

	set @SubjectLine = 'OFFER UPLOAD STATUS : ERROR : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID) + ' for Reference : '+ @VendorReferenceNo

	set @ResultFlag = 1

	GOTO PUBLISHEMAIL

End

--------------------------------------------------------
-- Use the Vendor offer date to manipulate the name of
-- folder where the offer file should exist.
--------------------------------------------------------

Declare @ReferenceFolderName varchar(200)

set @ReferenceFolderName = replace(@VendorReferenceNo , '/' , '_') + '_' + @VendorOfferType

select @VendorOfferDirectory = 
      @DefaultVendorUploadDir +
      convert(varchar(2) , day(@VendorOfferDate ) ) +
      case month(@VendorOfferDate)
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
      convert(varchar(4) , year(@VendorOfferDate ) ) 


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

    set @ErrorDescription = 'ERROR!!! Vendor Offer Directory ' + @VendorOfferDirectory + ' does not exist or is invalid'
	set @ErrorMsgStr = '<b>VALIDATION ERROR:</b>' + '<br><br>'+
					 '<b>ERROR!!! Vendor Offer Directory ' + @VendorOfferDirectory + ' does not exist or is invalid</b>'

	set @SubjectLine = 'OFFER UPLOAD STATUS : ERROR : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID) + ' for Reference : '+ @VendorReferenceNo
	
	set @ResultFlag = 1

    GOTO PUBLISHEMAIL

End

delete from #tempCommandoutput
where CommandOutput is NULL 

select @ReferenceFolderName = LTRIM(rtrim(CommandOutput))
from #tempCommandoutput
where CHARINDEX(@ReferenceFolderName ,CommandOutput) <> 0 

set @VendorOfferDirectory  = @VendorOfferDirectory + '\' + @ReferenceFolderName + '\'

Drop table #tempCommandoutput
     
----------------------------------------------------------------------
-- Check if the file attached to the VendorOfferID exists or not
----------------------------------------------------------------------    

set @FileExists = 0
set @AbsoluteVendorFileName = @VendorOfferDirectory + @VendorFileName 

--Select @AbsoluteVendorFileName

Exec master..xp_fileexist @AbsoluteVendorFileName , @FileExists output  

if ( @FileExists <> 1 )
Begin

    set @ErrorDescription = 'Error !!! Validated Offer file : ' + @VendorFileName + ' attached to the VendorOfferID : ' + convert(varchar(20), @VendorOfferID) +' does not exist'
	set @ErrorMsgStr = '<b>VALIDATION ERROR:</b>' + '<br><br>'+
					 '<b>Error !!! Validated Offer file : ' + @VendorFileName + ' attached to the VendorOfferID : ' + convert(varchar(20), @VendorOfferID) +' does not exist</b>'

	set @SubjectLine = 'OFFER UPLOAD STATUS : ERROR : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID) + ' for Reference : '+ @VendorReferenceNo

	set @ResultFlag = 1

	GOTO PUBLISHEMAIL      

End 

-----------------------------------------------------------------------
-- Get the RandomID values, which will help isolate the offer uploaded
-- in a unique manner.
-----------------------------------------------------------------------

if ( @VendorValueSourceID is not null )
Begin

	set @RandomIDMainOffer = convert(int ,substring(@RandomIDValue , 1 , charindex('|' , @RandomIDValue) - 1 ))
	set @RandomIDValueOffer = convert(int ,substring(@RandomIDValue ,charindex('|' , @RandomIDValue) + 1 , len(@RandomIDValue)))

End

Else
Begin

	set @RandomIDMainOffer = convert(int , @RandomIDValue)

End

---------------------------------------------------------------------
-- Check the uCLICK tables to establish the details of the processed
-- file.
----------------------------------------------------------------------

set @UploadFileName = @VendorFileName
set @UploadFileName = replace(REPLACE(@UploadFileName , '[', '') , ']' , '')  
set @UploadFileName = replace(REPLACE(@UploadFileName , '(' , '')  , ')' , '')  


--if not exists ( select 1 from BISERVER.UC_Commerce.dbo.tb_Offer where offerID = @RandomIDMainOffer )
--Begin

--		set @ErrorMsgStr = '
--					
--						 <b>PROCESS ERROR:</b>
--						 <b>ERROR!!! There is no offer Registered in downstream system for the Vendor Offer with ID :' + CONVERT(varchar(20) , @VendorOfferID)+ 'for Reference : ' + @VendorReferenceNo + '</b>
--					
--				     '
--		set @SubjectLine = 'OFFER UPLOAD STATUS : ERROR : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID) + ' for Reference : '+ @VendorReferenceNo
		
--		set @ResultFlag = 1

--		GOTO PUBLISHEMAIL 

--End

if not exists ( 
				select 1 
				from Referenceserver.UC_Commerce.dbo.tb_Offer 
				where offerID = @RandomIDMainOffer
			  )
Begin

        set @ErrorDescription = 'ERROR!!! There is no offer Registered in downstream system for the Vendor Offer with ID :' + CONVERT(varchar(20) , @VendorOfferID)+ 'for Reference : ' + @VendorReferenceNo
		set @ErrorMsgStr = '<b>PROCESS ERROR:</b>' + '<br><br>'+
						 '<b>ERROR!!! There is no offer Registered in downstream system for the Vendor Offer with ID :' + CONVERT(varchar(20) , @VendorOfferID)+ 'for Reference : ' + @VendorReferenceNo + '</b>'

		set @SubjectLine = 'OFFER UPLOAD STATUS : ERROR : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID) + ' for Reference : '+ @VendorReferenceNo
		
		set @ResultFlag = 1

		GOTO PUBLISHEMAIL 

End

------------------------------------------------------------
-- Get the status of the offer from the downstream system
-------------------------------------------------------------

Declare @OfferUploadStatusID int

--select @OfferUploadStatusID = OfferStatusID
--from BIServer.UC_Commerce.dbo.tb_OfferWorkflow
--where offerID = @RandomIDMainOffer
--and ModifiedDate = 
--(
--	select max(ModifiedDate)
--	from BIServer.UC_Commerce.dbo.tb_OfferWorkflow
--	where offerID = @RandomIDMainOffer
--)


select @OfferUploadStatusID = OfferStatusID
from Referenceserver.UC_Commerce.dbo.tb_OfferWorkflow
where offerID = @RandomIDMainOffer
and ModifiedDate = 
(
	select max(ModifiedDate)
	from ReferenceServer.UC_Commerce.dbo.tb_OfferWorkflow
	where offerID = @RandomIDMainOffer
)


select @OfferUploadStatusID as OfferUploadStatusID


 --------------------------------------------------------------
 -- If the offer is is any of the following status, then it 
 -- indicates that the offer has been loaded:
 -- Export Successful
 -- Analysis Exported
 --------------------------------------------------------------

 if (@OfferUploadStatusID in (6,13) )
 Begin

		GOTO CHECKVALUEOFFER

 End


---------------------------------------------------------------
-- If offer has any of the following failure status, then raise
-- exception :
-- Upload Failed
-- Export Failed
----------------------------------------------------------------

if ( @OfferUploadStatusID in (4,7,9,12) )
Begin
    
	    set @ErrorDescription = 
			Case
			   when @OfferUploadStatusID = 4  then -- Upload of offer Failed
					'ERROR!!! Vendor offer upload into downstream system failed' 
			   when @OfferUploadStatusID = 7  then -- Export of offer Failed
					'ERROR!!! Vendor offer uploaded into downstream system, but the export of offer into reference failed'
			   when @OfferUploadStatusID = 9  then -- Analysis of offer Failed
					'ERROR!!! Vendor offer uploaded and exported to downstream, but the Reference Dial code analysis failed' 
			   when @OfferUploadStatusID = 12  then -- Analysis Export of offer Failed
					'ERROR!!! Vendor rates exported and Reference Dial Code analysis completed. Export of analyzed reference rates failed'
			End

		set @ErrorMsgStr = 
		
		    Case
			   when @OfferUploadStatusID = 4  then -- Upload of offer Failed
					'<b>PROCESS ERROR:</b>' +'<br><br>'+
					'<b>ERROR!!! Vendor offer upload into downstream system failed </b>'
			   when @OfferUploadStatusID = 7  then -- Export of offer Failed
					'<b>PROCESS ERROR:</b>' + '<br><br>'+
					'<b>ERROR!!! Vendor offer uploaded into downstream system, but the export of offer into reference failed </b>'
			   when @OfferUploadStatusID = 9  then -- Analysis of offer Failed
					'<b>PROCESS ERROR:</b>' + '<br><br>'+
					'<b>ERROR!!! Vendor offer uploaded and exported to downstream, but the Reference Dial code analysis failed </b>'
			   when @OfferUploadStatusID = 12  then -- Analysis Export of offer Failed
					'<b>PROCESS ERROR:</b>' + '<br><br>'+
					'<b>ERROR!!! Vendor rates exported and Reference Dial Code analysis completed. Export of analyzed reference rates failed</b>'
			End

		set @SubjectLine = 'OFFER UPLOAD STATUS : ERROR : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID) + ' for Reference : '+ @VendorReferenceNo
		
		set @ResultFlag = 1

		GOTO PUBLISHEMAIL 

End

---------------------------------------------------------
-- If the offer processing is in progress then exit
-- Created
-- Upload InProgress
-- Upload Successful
-- Export InProgress
-- Analysis InProgress
-- Analysis Failed
-- Analysis Export InProgress
----------------------------------------------------------
 
 if ( @OfferUploadStatusID in (1,2,3,5,8,11) )
 Begin

		Return 0

 End


 CHECKVALUEOFFER:


----------------------------------------------------------------------------------
-- If the Value Vendor SourceID is not NULL, then it implies that the offer has to
-- be loaded for both sources.
-- Check to make sure that the secondary offer has also been loaded successfully, and
-- then proceeed with updating the status of the offer upload.
----------------------------------------------------------------------------------

if ( @VendorValueSourceID is not NULL )
Begin


			--if not exists ( select 1 from BISERVER.UC_Commerce.dbo.tb_Offer where offerID = @RandomIDValueOffer )
			--Begin

			--		set @ErrorMsgStr = '
			--					
			--						 <b>PROCESS ERROR:</b>
			--						 <b>ERROR!!! There is no SECONDARY offer Registered in downstream system for the Vendor Offer with ID :' + CONVERT(varchar(20) , @VendorOfferID)+ 'for Reference : ' + @VendorReferenceNo + '</b>
			--					
			--				     '
			--		set @SubjectLine = 'OFFER UPLOAD STATUS : ERROR : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID) + ' for Reference : '+ @VendorReferenceNo
		
			--		set @ResultFlag = 1

			--		GOTO PUBLISHEMAIL 

			--End

			if not exists ( select 1 from Referenceserver.UC_Commerce.dbo.tb_Offer 	where offerID = @RandomIDValueOffer )
			Begin

			        set @ErrorDescription = 'ERROR!!! There is no SECONDARY offer Registered in downstream system for the Vendor Offer with ID :' + CONVERT(varchar(20) , @VendorOfferID)+ 'for Reference : ' + @VendorReferenceNo

					set @ErrorMsgStr = '<b>PROCESS ERROR:</b>' + '<br><br>'+
									 '<b>ERROR!!! There is no SECONDARY offer Registered in downstream system for the Vendor Offer with ID :' + CONVERT(varchar(20) , @VendorOfferID)+ 'for Reference : ' + @VendorReferenceNo + '</b>'

					set @SubjectLine = 'OFFER UPLOAD STATUS : ERROR : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID) + ' for Reference : '+ @VendorReferenceNo
		
					set @ResultFlag = 1

					GOTO PUBLISHEMAIL 

			End

			------------------------------------------------------------
			-- Get the status of the offer from the downstream system
			-------------------------------------------------------------

			--select @OfferUploadStatusID = OfferStatusID
			--from BIServer.UC_Commerce.dbo.tb_OfferWorkflow
			--where offerID = @@RandomIDValueOffer
			--and ModifiedDate = 
			--(
			--	select max(ModifiedDate)
			--	from BIServer.UC_Commerce.dbo.tb_OfferWorkflow
			--	where offerID = @@RandomIDValueOffer
			--)


			select @OfferUploadStatusID = OfferStatusID
			from Referenceserver.UC_Commerce.dbo.tb_OfferWorkflow
			where offerID = @RandomIDValueOffer
			and ModifiedDate = 
			(
				select max(ModifiedDate)
				from Referenceserver.UC_Commerce.dbo.tb_OfferWorkflow
				where offerID = @RandomIDValueOffer
			)


			 --------------------------------------------------------------
			 -- If the offer is is any of the following status, then it 
			 -- indicates that the offer has been loaded:
			 -- Export Successful
			 -- Analysis Exported
			 --------------------------------------------------------------

			 if (@OfferUploadStatusID in (6,13) )
			 Begin

					GOTO PROCESSOFFERSTATISTICS

			 End


			---------------------------------------------------------------
			-- If offer has any of the following failure status, then raise
			-- exception :
			-- Upload Failed
			-- Export Failed
			----------------------------------------------------------------

			if ( @OfferUploadStatusID in (4,7,9,12) )
			Begin

					set @ErrorDescription = 
		
						Case
						   when @OfferUploadStatusID = 4  then -- Upload of offer Failed
								'ERROR!!! Secondary Vendor offer upload into downstream system failed'
						   when @OfferUploadStatusID = 7  then -- Export of offer Failed
								'ERROR!!! Secondary Vendor offer uploaded into downstream system, but the export of offer into reference failed'
						   when @OfferUploadStatusID = 9  then -- Analysis of offer Failed
								'ERROR!!! Secondary Vendor offer uploaded and exported to downstream, but the Reference Dial code analysis failed' 
						   when @OfferUploadStatusID = 12  then -- Analysis Export of offer Failed
								'ERROR!!! Secondary Vendor offer rates exported and Reference Dial Code analysis completed. Export of analyzed reference rates failed'
						End

					set @ErrorMsgStr = 
		
						Case
						   when @OfferUploadStatusID = 4  then -- Upload of offer Failed
								'<b>PROCESS ERROR:</b>' + '<br><br>'+
								'<b>ERROR!!! Secondary Vendor offer upload into downstream system failed </b>'
						   when @OfferUploadStatusID = 7  then -- Export of offer Failed
								'<b>PROCESS ERROR:</b>' + '<br><br>'+
								'<b>ERROR!!! Secondary Vendor offer uploaded into downstream system, but the export of offer into reference failed </b>'
						   when @OfferUploadStatusID = 9  then -- Analysis of offer Failed
								'<b>PROCESS ERROR:</b>' + '<br><br>'+
								'<b>ERROR!!! Secondary Vendor offer uploaded and exported to downstream, but the Reference Dial code analysis failed </b>'
						   when @OfferUploadStatusID = 12  then -- Analysis Export of offer Failed
								'<b>PROCESS ERROR:</b>' + '<br><br>'+
								'<b>ERROR!!! Secondary Vendor offer rates exported and Reference Dial Code analysis completed. Export of analyzed reference rates failed</b>'

						End

					set @SubjectLine = 'OFFER UPLOAD STATUS : ERROR : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID) + ' for Reference : '+ @VendorReferenceNo
		
					set @ResultFlag = 1

					GOTO PUBLISHEMAIL 

			End

			---------------------------------------------------------
			-- If the offer processing is in progress then exit
			-- Created
			-- Upload InProgress
			-- Upload Successful
			-- Export InProgress
			-- Analysis InProgress
			-- Analysis Failed
			-- Analysis Export InProgress
			-- Analysis Exported
			---------------------------------------------------------
 
			 if ( @OfferUploadStatusID in (1,2,3,5,8,11) )
			 Begin

					Return 0

			 End

			 
End



PROCESSOFFERSTATISTICS:

--------------------------------------------------------
-- Get the offer process statistics from the log tables
--------------------------------------------------------

--------------------------------------
-- Prepare the Process_Details file.
--------------------------------------

Declare @ProcessDetailsFileName varchar(1000),
        @TotalDestinations int,
		@TotalRates int,
		@TotalDialedDigits int,
		@NewOfferStatus varchar(100)

set @ProcessDetailsFileName = @VendorOfferDirectory + 'VendorOffer('+ convert(varchar(20) , @VendorOfferID) + ')_ProcessDetails.Log'

Exec SP_LogMessage NULL , @ProcessDetailsFileName
set @ErrorMsgStr = '==============================================================='
Exec SP_LogMessage @ErrorMsgStr , @ProcessDetailsFileName

set @ErrorMsgStr = '********************* FILE UPLOAD RESULT ********************'
Exec SP_LogMessage @ErrorMsgStr , @ProcessDetailsFileName

set @ErrorMsgStr = '==============================================================='
Exec SP_LogMessage @ErrorMsgStr , @ProcessDetailsFileName

--select @TotalDestinations = count(distinct DestinationID)
--from BIServer.UC_Commerce.dbo.tb_UploadDestination
--where offerID = @RandomIDMainOffer

--select @TotalRates = count(*)
--from BIServer.UC_Commerce.dbo.tb_UploadRate
--where offerID = @RandomIDMainOffer


--select @TotalDialedDigits = count(distinct DialedDigit)
--from BIServer.UC_Commerce.dbo.tb_UploadBreakout
--where offerID = @RandomIDMainOffer


select @TotalDestinations = count(distinct DestinationID)
from Referenceserver.UC_Commerce.dbo.tb_UploadDestination
where offerID = @RandomIDMainOffer

select @TotalRates = count(*)
from Referenceserver.UC_Commerce.dbo.tb_UploadRate
where offerID = @RandomIDMainOffer

select @TotalDialedDigits = count(distinct DialedDigit)
from Referenceserver.UC_Commerce.dbo.tb_UploadBreakout
where offerID = @RandomIDMainOffer

set @ErrorMsgStr = '	Total Destinations  :- ' + convert(varchar(20) , @TotalDestinations)
Exec SP_LogMessage @ErrorMsgStr , @ProcessDetailsFileName

set @ErrorMsgStr = '	Total Dialed Digits :- ' + convert(varchar(20) , @TotalDialeddigits)
Exec SP_LogMessage @ErrorMsgStr , @ProcessDetailsFileName

set @ErrorMsgStr = '	Total Rates         :- ' + convert(varchar(20) , @TotalRates)
Exec SP_LogMessage @ErrorMsgStr , @ProcessDetailsFileName

set @ErrorMsgStr = '==============================================================='
Exec SP_LogMessage @ErrorMsgStr , @ProcessDetailsFileName

------------------------------------------------------------------------
-- Get then name of the offer as per loaded into the downstream system
------------------------------------------------------------------------

--select @LoadOfferName = offerFileName
--from BIServer.UC_Commerce.dbo.tb_Offer
--where offerID = @RandomIDMainOffer

select @LoadOfferName = offerFileName
from Referenceserver.UC_Commerce.dbo.tb_Offer
where offerID = @RandomIDMainOffer

---------------------------------------------------------------------
-- Get the modified date from the downstream offer status workflow
-- table indicating when the offer was loaded into the system
--------------------------------------------------------------------

--select @UploadOfferProcessDate =   max(ModifiedDate)
--from BIServer.dbo.UC_Commerce.dbo.tb_OfferWorkflow
--where offerID = @RandomIDMainOffer

select @UploadOfferProcessDate =   max(ModifiedDate)
from Referenceserver.UC_Commerce.dbo.tb_OfferWorkflow
where offerID = @RandomIDMainOffer
and OfferStatusID  = 6 -- Export Successful

------------------------------------------------
-- Update the status of the file to processed
-- or partially processed,depending on the
-- Partial Process Flag
------------------------------------------------

if ( (@PartialOfferProcessFlag = 0 ) )
Begin

		-----------------------------------------------
		-- Update the status of the file as Processed 
		----------------------------------------------- 

		select @NewOfferStatus = OfferStatus
		from tb_OfferStatus
		where OfferStatusID = 7

		update TB_VendorOfferDetails
		set LoadOfferName = @LoadOfferName,
		    OfferProcessDate = @UploadOfferProcessDate,
		    OfferStatusID = 7,
			OfferStatus = @NewOfferStatus,
			ModifiedByID = @UserID,
			ModifiedDate = GetDate()
		where VendorOfferID = @VendorOfferID
		    

End

Else
Begin

		--------------------------------------------------------
		-- Update the status of the file as Partially Processed 
		-------------------------------------------------------- 

		select @NewOfferStatus = OfferStatus
		from tb_OfferStatus
		where OfferStatusID = 8

		update TB_VendorOfferDetails
		set LoadOfferName = @LoadOfferName,
			OfferProcessDate = @UploadOfferProcessDate,
		    OfferStatusID = 8,
			OfferStatus = @NewOfferStatus,
			ModifiedByID = @UserID,
			ModifiedDate = GetDate()
		where VendorOfferID = @VendorOfferID

End


set @ErrorMsgStr = '<b>Offer by the name : '+ @LoadOfferName + '  for Vendor Offer with ID : '+convert(varchar(20) , @VendorOfferID)+' has been successfully Loaded into downstream system</b>' + '<br><br>'
set @SubjectLine = 'OFFER UPLOAD STATUS : SUCCESS : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID) + ' for Reference : '+ @VendorReferenceNo
set @Attachment = @ProcessDetailsFileName 


PUBLISHEMAIL:


-------------------------------------------------------------------
-- Send an email to the configured list of recipients reflecting
-- the progress on the offer.
-------------------------------------------------------------------

select @EmailAddress = ConfigValue
from tb_config
where configname = 'UploadOfferAlertEmailAddress'

if (@ResultFlag = 1)
Begin

       ---------------------------------------------------------
       -- Update the status of file to UPLOAD ERROR, so that it
       -- is not picked up again by the status check process
       ---------------------------------------------------------

		select @NewOfferStatus = OfferStatus
		from tb_OfferStatus
		where OfferStatusID = 10

		update TB_VendorOfferDetails
		set OfferStatusID = 10,
			OfferStatus = @NewOfferStatus,
			ModifiedByID = @UserID,
			ModifiedDate = GetDate()
		where VendorOfferID = @VendorOfferID

		if ( @EmailAddress is not null )
		Begin

			select  @EmailAddress, @SubjectLine, @ErrorMsgStr , @Attachment

			Exec SP_SendEmailAlerts @EmailAddress, @SubjectLine, @ErrorMsgStr , NULL


		End


End

Else
Begin

		if ( @EmailAddress is not null )
		Begin

			select  @EmailAddress, @SubjectLine, @ErrorMsgStr , @Attachment

			Exec SP_SendEmailAlerts @EmailAddress, @SubjectLine, @ErrorMsgStr , @Attachment


		End


End

Return 0
GO
