USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_SetVendorOfferProcessStatus_IXTools]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[SP_SetVendorOfferProcessStatus_IXTools]
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
        @VendorOfferStatus varchar(100),
		@VendorOfferStatusID int,
        @VendorReferenceNo varchar(100),
        @FileExists int,
        @VendorFileName varchar(500),
	    @AbsoluteVendorFileName varchar(500),
	    @VendorOfferType varchar(100),
	    @VendorSourceid int,
            @VendorValueSourceid int ,
	    @UploadFileName varchar(200),
	    @UploadLogID int,
        @OfferName varchar(200),
        @Command varchar(4000),
        @UploadOfferContentType varchar(50),
        @UploadOfferProcessDate datetime,
        @ResponseFileName varchar(500),
        @ExcelFileName varchar(200),
        @RegistryStatusID int,
	@EmailAddress Varchar(2000),
        @SubjectLine Varchar(2000),
	@LoadExcelFileName varchar(1000),
	@LoadOfferName varchar(200),
	@Attachment varchar(5000),
	@ErrorFlag int,
	@PartialOfferProcessFlag int,
	@UploadOfferType varchar(100),
	@RandomIDValue varchar(100),
	@RandomIDMainOffer int,
	@RandomIDValueOffer int

set @ErrorFlag = 0

set @ResultFlag = 0
set @ErrorDescription = NULL

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
-- Find the directory in which the vendor file
-- located.
-- Also find the offer status.
---------------------------------------------------

select @VendorOfferDate = tbl1.offerreceivedate,
       @VendorOfferStatusID = tbl1.offerstatusID,
       @VendorOfferStatus = tbl1.offerstatus,
       @VendorReferenceNo = tbl2.ReferenceNo,
       @VendorFileName = tbl1.ValidatedOfferFileName,
       @VendorOfferType = tbl1.OfferType,
       @UploadOfferType = tbl1.UploadOfferType,
       @VendorSourceid = tbl2.VendorSourceid,
       @VendorValueSourceid  =  tbl2.VendorValueSourceid,
       @PartialOfferProcessFlag = PartialOfferProcessFlag,
       @RandomIDValue = RandomIDValue
from tb_vendorofferdetails tbl1  
inner join TB_VendorReferenceDetails tbl2 on tbl1.Referenceid = tbl2.ReferenceID
where VendorOfferID =  @VendorOfferID 

---------------------------------------------------
-- Check if the Vendor offer is in Processing state.
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

if ( @VendorValueSourceid is not null )
Begin

	set @RandomIDMainOffer = convert(int ,substring(@RandomIDValue , 1 , charindex('|' , @RandomIDValue) - 1 ))
	set @RandomIDValueOffer = convert(int ,substring(@RandomIDValue ,charindex('|' , @RandomIDValue) + 1 , len(@RandomIDValue)))

End

Else
Begin

	set @RandomIDMainOffer = convert(int , @RandomIDValue)

End

---------------------------------------------------------------------
-- Check the IXTOOLs tables to establish the details of the processed
-- file.
----------------------------------------------------------------------

--set @UploadFileName = REPLACE(@VendorFileName, '.xls' , '')  

set @UploadFileName = substring(@VendorFileName, 1 ,len(@VendorFileName) - 4)
set @UploadFileName = replace(REPLACE(@UploadFileName , '[', '') , ']' , '')  
set @UploadFileName = replace(REPLACE(@UploadFileName , '(' , '')  , ')' , '')  


select @UploadLogID = UploadLogID,
       @OfferName = offername,
       @ExcelFileName  = ExcelFileName
from referenceserver.ixtrade_main.dbo.tbuploadlog 
where replace(replace(replace(REPLACE(UploadFileName , '[' , '')  , ']' , '') ,'(' , ''),')' , '') like @UploadFileName+'%'
and UploadFileExtension = 'xls'
and Sourceid = @VendorSourceid
and datediff(dd , offerdate , @VendorOfferDate) = 0
and offercontent = 
    Case
	When @UploadOfferType = 'AZ' then 'A-Z'
	When @UploadOfferType = 'FC' then 'Full Country'
	When @UploadOfferType = 'PR' then 'Partial'
    End
and StatusID = 119
and RandomID = @RandomIDMainOffer

if ( @UploadLogID is NULL )
Begin

       --------------------------------------------------------------------
       -- This means that there can be either of the two cases here:
       -- 1.  The offer is still sitting in waiting/ready/running state
       -- 2. The offer has failed in the first step of XML conversion.
       -- 3. The offer has still not registered for processing
       --------------------------------------------------------------------

	select @ExcelFileName  = ExcelFileName
	from referenceserver.ixtrade_main.dbo.tbuploadlog 
	where replace(replace(replace(REPLACE(UploadFileName , '[' , '')  , ']' , '') ,'(' , ''),')' , '') like @UploadFileName+'%'
	and UploadFileExtension = 'xls'
	and Sourceid = @VendorSourceid
	and datediff(dd , offerdate , @VendorOfferDate) = 0
	and offercontent = 
	    Case
		When @UploadOfferType = 'AZ' then 'A-Z'
		When @UploadOfferType = 'FC' then 'Full Country'
		When @UploadOfferType = 'PR' then 'Partial'
	    End
	and StatusID = 118
	and RandomID = @RandomIDMainOffer

	select @RegistryStatusID  = reg.statusid
	from referenceserver.ixcontrol_main.dbo.tbregistry reg
	inner join referenceserver.ixcontrol_main.dbo.tbObject obj on reg.ObjectID = obj.ObjectID
	inner join referenceserver.ixcontrol_main.dbo.tbObjectType objtype on obj.ObjectTypeID = objtype.ObjectTypeID
	where objtype.ObjectType = 'Data File'
	and obj.ObjectName = 'Vendor Offer Upload'
	and reg.Registry = @ExcelFileName

	if ( @RegistryStatusID = 105014 ) -- Upload Failed
	Begin

	    set @ErrorDescription = 'ERROR!!! There is no offer uploaded in IXTOOLS with SUCCESSFUL XML conversion for the Vendor Offer with ID :' + CONVERT(varchar(20) , @VendorOfferID)
		set @ErrorMsgStr = '<b>PROCESS ERROR:</b>' + '<br><br>'+
						   '<b>ERROR!!! There is no offer uploaded in IXTOOLS with SUCCESSFUL XML conversion for the Vendor Offer with ID :' + CONVERT(varchar(20) , @VendorOfferID)+'</b>'
		set @SubjectLine = 'OFFER UPLOAD STATUS : ERROR : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID) + ' for Reference : '+ @VendorReferenceNo
		
		set @ResultFlag = 1

		GOTO PUBLISHEMAIL 

	End

	Else
	Begin

		    set @ErrorMsgStr = 
		       Case
			   When @RegistryStatusID is NULL Then
				    'INFO : The offer with ID :' + CONVERT(varchar(20) , @VendorOfferID) + ' is still not registered for processing'
			   When @RegistryStatusID in ( 105010 , 105011) Then
				    'INFO : The offer with ID :' + CONVERT(varchar(20) , @VendorOfferID) + ' is still pending conversion to XML'
			   When @RegistryStatusID = 105012 Then
				    'INFO : The offer with ID :' + CONVERT(varchar(20) , @VendorOfferID) + ' is currently being converted to XML'
		       End

		    print @ErrorMsgStr
		    return 0 
	       
	End

 

End

----------------------------------------------------------------------
-- Check if Vendor offer has been regsistered in the TBOFFER table
-- with COMPLETED Status.
------------------------------------------------------------------------------------------
-- At this juncture, either upload of offer is running , failed or completed successfully.
------------------------------------------------------------------------------------------

set @LoadExcelFileName = @ExcelFileName
set @LoadOfferName = @OfferName

set @RegistryStatusID = NULL

select @RegistryStatusID  = reg.statusid
from referenceserver.ixcontrol_main.dbo.tbregistry reg
inner join referenceserver.ixcontrol_main.dbo.tbObject obj on reg.ObjectID = obj.ObjectID
inner join referenceserver.ixcontrol_main.dbo.tbObjectType objtype on obj.ObjectTypeID = objtype.ObjectTypeID
where objtype.ObjectType = 'Data File'
and obj.ObjectName = 'Vendor Offer Upload'
and reg.Registry = @ExcelFileName

if ( @RegistryStatusID <> 105013 )
Begin

		if ( @RegistryStatusID = 105014 ) -- Upload Failed for main offer at XML translation stage
		Begin

		    set @ErrorDescription = 'ERROR!!! The IXTOOLs Offer file ' + @OfferName + ' has been converted to XML, but not loaded in database successfully for Vendor Offer ID  :' + CONVERT(varchar(20) , @VendorOfferID)
			set @ErrorMsgStr = '<b>PROCESS ERROR:</b>'+ '<br><br>'+
							   '<b>ERROR!!! The IXTOOLs Offer file ' + @OfferName + ' has been converted to XML, but not loaded in database successfully for Vendor Offer ID  :' + CONVERT(varchar(20) , @VendorOfferID)+'</b>'
			set @SubjectLine = 'OFFER UPLOAD STATUS : ERROR : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID) + ' for Reference : '+ @VendorReferenceNo

			set @ResultFlag = 1

			GOTO PUBLISHEMAIL 

		End

		if ( @RegistryStatusID = 105012 ) -- Upload Running
		Begin

		    set @ErrorMsgStr = 'INFO!!! The IXTOOLs Offer file ' + @OfferName + ' has been converted to XML, but upload in database currently running for Vendor Offer ID  :' + CONVERT(varchar(20) , @VendorOfferID)
		    print @ErrorMsgStr
		    return 0 

		End

End



----------------------------------------------------------------------------------
-- If the Value Vendor SourceID is not NULL, then it implies that the offer has to
-- be loaded for both IDD and VIDD sources.
-- Check to make sure that the VIDD offer has also been loaded successfully, and
-- then proceeed with updating the status of the offer upload.
----------------------------------------------------------------------------------

if ( @VendorValueSourceid is not NULL )
Begin

	--------------------------------------------------------
	-- Extract the name of the uploaded VIDD offer file
	-- from th tbupload log tables
	--------------------------------------------------------

        set @UploadLogID  = NULL
        set @OfferName  = NULL
        set @RegistryStatusID = NULL
        set @ExcelFileName = NULL

	select @UploadLogID = UploadLogID,
       		@OfferName = offername,
		@ExcelFileName = ExcelFileName
	from referenceserver.ixtrade_main.dbo.tbuploadlog 
	where replace(replace(replace(REPLACE(UploadFileName , '[' , '')  , ']' , '') ,'(' , ''),')' , '') like @UploadFileName+'%'
	and UploadFileExtension = 'xls'
	and Sourceid = @VendorValueSourceid
	and datediff(dd , offerdate , @VendorOfferDate) = 0
	and offercontent = 
	    Case
		When @UploadOfferType = 'AZ' then 'A-Z'
		When @UploadOfferType = 'FC' then 'Full Country'
		When @UploadOfferType = 'PR' then 'Partial'
	    End
	and StatusID = 119
	and RandomID = @RandomIDValueOffer

	if ( @UploadLogID is NULL )
	Begin

	       -----------------------------------------------------------------------
	       -- This means that there can be either of the two cases here for VIDD :
	       -- 1.  The offer is still sitting in waiting/ready/running state
	       -- 2. The offer has failed in the first step of XML conversion.
	       -- 3. The offer has still not registered for processing
	       --------------------------------------------------------------------


		set @ExcelFileName = NULL

		select @ExcelFileName = ExcelFileName
		from referenceserver.ixtrade_main.dbo.tbuploadlog 
		where replace(replace(replace(REPLACE(UploadFileName , '[' , '')  , ']' , '') ,'(' , ''),')' , '') like @UploadFileName+'%'
		and UploadFileExtension = 'xls'
		and Sourceid = @VendorValueSourceid
		and datediff(dd , offerdate , @VendorOfferDate) = 0
		and StatusID = 118
		and offercontent = 
		    Case
			When @UploadOfferType = 'AZ' then 'A-Z'
			When @UploadOfferType = 'FC' then 'Full Country'
			When @UploadOfferType = 'PR' then 'Partial'
		    End
		and RandomID = @RandomIDValueOffer

		 set @RegistryStatusID = NULL

		select @RegistryStatusID  = reg.statusid
		from referenceserver.ixcontrol_main.dbo.tbregistry reg
		inner join referenceserver.ixcontrol_main.dbo.tbObject obj on reg.ObjectID = obj.ObjectID
		inner join referenceserver.ixcontrol_main.dbo.tbObjectType objtype on obj.ObjectTypeID = objtype.ObjectTypeID
		where objtype.ObjectType = 'Data File'
		and obj.ObjectName = 'Vendor Offer Upload'
		and reg.Registry = @ExcelFileName

		if ( @RegistryStatusID = 105014 ) -- Upload Failed for VIDD offer at XML translation stage
		Begin 

		    set @ErrorDescription = 'ERROR!!! The VIDD offer for the main offer with ID :' + CONVERT(varchar(20) , @VendorOfferID)
			set @ErrorMsgStr = '<b>PROCESS ERROR:</b>'+ '<br><br>'+
							   '<b>ERROR!!! The VIDD offer for the main offer with ID :' + CONVERT(varchar(20) , @VendorOfferID)+' has failed conversion to XML</b>'
			set @SubjectLine = 'OFFER UPLOAD STATUS : ERROR : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID) + ' for Reference : '+ @VendorReferenceNo

			set @ResultFlag = 1

			GOTO PUBLISHEMAIL 

		End

		Else
		Begin

			    set @ErrorMsgStr = 
			       Case
			           When @RegistryStatusID is NULL Then
					     'INFO : The VIDD offerfor main offer with ID :' + CONVERT(varchar(20) , @VendorOfferID) + ' is still not registered for processing'
				   When @RegistryStatusID in ( 105010 , 105011) Then
					    'INFO : The VIDD offer for main offer with ID :' + CONVERT(varchar(20) , @VendorOfferID) + ' is still pending conversion to XML'
				   When @RegistryStatusID = 105012 Then
					    'INFO : The VIDD offer for main offer with ID :' + CONVERT(varchar(20) , @VendorOfferID) + ' is currently being converted to XML'
			       End

			    print @ErrorMsgStr
			    return 0 
		       
		End
	
	End

	set @RegistryStatusID = NULL

	select @RegistryStatusID  = reg.statusid
	from referenceserver.ixcontrol_main.dbo.tbregistry reg
	inner join referenceserver.ixcontrol_main.dbo.tbObject obj on reg.ObjectID = obj.ObjectID
	inner join referenceserver.ixcontrol_main.dbo.tbObjectType objtype on obj.ObjectTypeID = objtype.ObjectTypeID
	where objtype.ObjectType = 'Data File'
	and obj.ObjectName = 'Vendor Offer Upload'
	and reg.Registry = @ExcelFileName

	if ( @RegistryStatusID <> 105013 )
	Begin

			if ( @RegistryStatusID = 105014 ) -- Upload Failed
			Begin

			    set @ErrorDescription = 'ERROR!!! The VIDD Offer file ' + @OfferName + ' has been converted to XML, but not loaded in database successfully for Vendor Offer ID  :' + CONVERT(varchar(20) , @VendorOfferID)
				set @ErrorMsgStr = '<b>PROCESS ERROR:</b>'+ '<br><br>'+
								   '<b>ERROR!!! The VIDD Offer file ' + @OfferName + ' has been converted to XML, but not loaded in database successfully for Vendor Offer ID  :' + CONVERT(varchar(20) , @VendorOfferID)+'</b>'
				set @SubjectLine = 'OFFER UPLOAD STATUS : ERROR : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID) + ' for Reference : '+ @VendorReferenceNo
		
				set @ResultFlag = 1

				GOTO PUBLISHEMAIL 

			End

			if ( @RegistryStatusID = 105012 ) -- Upload Running
			Begin

			    set @ErrorMsgStr = 'INFO!!! The VIDD Offer file ' + @OfferName + ' has been converted to XML, but upload in database currently running for Vendor Offer ID  :' + CONVERT(varchar(20) , @VendorOfferID)
			    print @ErrorMsgStr
			    return 0 

			End

	End


End


--------------------------------------------------------
-- Get the offer process statistics from the log tables
--------------------------------------------------------

--------------------------------------
-- Prepare the Process_Details file.
--------------------------------------

Declare @ProcessDetailsFileName varchar(1000),
        @VarMoreInfo varchar(2000),
		@NewOfferStatus varchar(100)

set @ProcessDetailsFileName = @VendorOfferDirectory + 'VendorOffer('+ convert(varchar(20) , @VendorOfferID) + ')_ProcessDetails.Log'

Exec SP_LogMessage NULL , @ProcessDetailsFileName
set @ErrorMsgStr = '==============================================================='
Exec SP_LogMessage @ErrorMsgStr , @ProcessDetailsFileName

set @ErrorMsgStr = '********************* FILE UPLOAD RESULT ********************'
Exec SP_LogMessage @ErrorMsgStr , @ProcessDetailsFileName

set @ErrorMsgStr = '==============================================================='
Exec SP_LogMessage @ErrorMsgStr , @ProcessDetailsFileName

Declare cur_get_loginfo Cursor For
select moreinfo 
from referenceserver.ixtrade_main.dbo.tbLog
where Log like '%'+'UploadLogID='+ CONVERT(varchar(100) , @UploadLogID) + '%'
and Type = 'VOTUpload'
and MoreInfo <> 'XML File generated successfully'

Open cur_get_loginfo
Fetch Next From cur_get_loginfo
Into @VarMoreInfo

While @@FETCH_STATUS = 0
Begin

		set @ErrorMsgStr = '	' + @VarMoreInfo
		Exec SP_LogMessage @ErrorMsgStr , @ProcessDetailsFileName

	        Fetch Next From cur_get_loginfo
		Into @VarMoreInfo

End

Close cur_get_loginfo
Deallocate cur_get_loginfo


set @ErrorMsgStr = '==============================================================='
Exec SP_LogMessage @ErrorMsgStr , @ProcessDetailsFileName

------------------------------------------------
-- Update the status of the file to processed
-- or partially processed, depending on the
-- register offer content versus processed 
-- offer content
------------------------------------------------

if exists ( select 1 from referenceserver.ixtrade_main.dbo.tbOffer where Offer = @LoadOfferName)
Begin

	select @UploadOfferContentType = 
		 Case 
		    When offercontent = 'A-Z' then 'AZ'
		    When offercontent = 'Full Country' then 'FC'            
		    When offercontent = 'Partial' then 'PR'
		 End ,      
	       @UploadOfferProcessDate = modifieddate
	from referenceserver.ixtrade_main.dbo.tbOffer
	where Offer = @LoadOfferName

End

Else
Begin

	set @ErrorDescription = 'ERROR!!! The Offer file ' + @LoadOfferName + ' for Vendor offer ID :' + CONVERT(varchar(20) , @VendorOfferID)+' does not have entry in the TBOFFER table'
	set @ErrorMsgStr = '<b>PROCESS ERROR:</b>'+ '<br><br>'+
					   '<b>ERROR!!! The Offer file ' + @LoadOfferName + ' for Vendor offer ID :' + CONVERT(varchar(20) , @VendorOfferID)+' does not have entry in the TBOFFER table</b>'
	set @SubjectLine = 'OFFER UPLOAD STATUS : ERROR : VENDOR OFFERID :' + convert(varchar(20) , @VendorOfferID) + ' for Reference : '+ @VendorReferenceNo
		
	set @ResultFlag = 1

	GOTO PUBLISHEMAIL
	

End
        

if ( ( @UploadOfferContentType = @VendorOfferType ) and (@PartialOfferProcessFlag = 0 ) )
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



set @ErrorMsgStr = '<b>Offer by the name : '+ @LoadOfferName + ' has been successfully Loaded into database for Vendor Offer with ID : '+convert(varchar(20) , @VendorOfferID)+'</b>' + '<br><br>'
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

			--select  @EmailAddress, @SubjectLine, @ErrorMsgStr , @Attachment

			Exec SP_SendEmailAlerts @EmailAddress, @SubjectLine, @ErrorMsgStr , NULL


		End
		
End

Else
Begin

		if ( @EmailAddress is not null )
		Begin

			--select  @EmailAddress, @SubjectLine, @ErrorMsgStr , @Attachment

			Exec SP_SendEmailAlerts @EmailAddress, @SubjectLine, @ErrorMsgStr , @Attachment


		End

End

Return 0
GO
