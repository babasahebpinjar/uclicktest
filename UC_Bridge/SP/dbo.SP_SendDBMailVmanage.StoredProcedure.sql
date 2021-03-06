USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_SendDBMailVmanage]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_SendDBMailVmanage]
(
	@VendorOfferID int
)
As

Declare @EmailAddress Varchar(2000),
        @SubjectLine Varchar(2000),
		@Attachment varchar(5000),
		@ErrorMsgStr varchar(2000),
		@DefaultVendorUploadDir varchar(500)

set @EmailAddress = 'jimmy.khiu@nexwavetelecoms.com;nexwave_ccpl@ccplglobal.com;kwongtai.hong@nexwavetelecoms.com'


-----------------------------------------------------------------------
-- Check to ensure that the offer in in processed state, before sending
-- the VMANAGE file
-----------------------------------------------------------------------

if not exists ( select 1 from tb_VendorOfferDetails where OfferStatusID in (7,8) and vendorofferID = @VendorOfferID )
Begin

			set @ErrorMsgStr = 
			'<html
					<body>
							<br><b>ERROR !!! Vendor Offer : '+ convert(varchar(100) , @VendorOfferID) +' not in processed state </b><br>
	
					</body>
			</html>'

			set @SubjectLine = 'VMANAGE File for offerID : ' + convert(varchar(100) , @VendorOfferID) 

			GOTO PUBLISHEMAIL

End


select @DefaultVendorUploadDir = configvalue
from TB_Config
where configname = 'VendorOfferDirectory'


if ( RIGHT(@DefaultVendorUploadDir, 1) <> '\' )
	set @DefaultVendorUploadDir = @DefaultVendorUploadDir + '\'



------------------------------------------------------------------------
-- Get all the essential details regarding the vendor offer for sending
-- email
------------------------------------------------------------------------

Declare @VendorOfferDate datetime,
        @VendorOfferDirectory varchar(500),
        @VendorOfferStatus varchar(100),
        @VendorReferenceNo varchar(100),
        @FileExists int,
        @VendorFileName varchar(500),
	    @AbsoluteVendorFileName varchar(500),
	    @VendorOfferType varchar(100),
		@Account varchar(100)

select @VendorOfferDate = tbl1.offerreceivedate,
       @VendorOfferStatus = tbl1.offerstatus,
       @VendorReferenceNo = tbl2.ReferenceNo,
       @VendorFileName = tbl1.OfferFileName,
       @VendorOfferType = tbl1.OfferType,
	   @Account = tbl2.Account
from tb_vendorofferdetails tbl1  
inner join TB_VendorReferenceDetails tbl2 on tbl1.Referenceid = tbl2.ReferenceID
where VendorOfferID =  @VendorOfferID 


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


set @VendorOfferDirectory  = @VendorOfferDirectory + '\' + @ReferenceFolderName + '\'

------------------------------------------------------------------------------
-- Set the name of the VManage file which needs to be send to NEXWAVE team
------------------------------------------------------------------------------

set @VendorFileName = reverse(substring(reverse(@VendorFileName), charindex('.' , reverse(@VendorFileName)) + 1 , len(reverse(@VendorFileName))))
set @VendorFileName = @VendorFileName + '_VManage.CSV'


----------------------------------------------------------------------
-- Check if the file attached to the VendorOfferID exists or not
----------------------------------------------------------------------    

set @FileExists = 0
set @AbsoluteVendorFileName = @VendorOfferDirectory + @VendorFileName 

--Select @AbsoluteVendorFileName

Exec master..xp_fileexist @AbsoluteVendorFileName , @FileExists output  

if ( @FileExists <> 1 )
Begin

			set @ErrorMsgStr = 
			'<html
					<body>
							<br><b>===================================</b></br>
							<br><b> VENDOR OFFER INFO                  </b></br>
							<br><b>====================================</b></br>
							<br>   Vendor Offer ID   : ' + convert(varchar(100) , @VendorOfferID) + '</br>
							<br>   Reference NO      : ' + @VendorReferenceNo + '</br>
							<br>   Account           : ' + @Account + '</br>
							<br>   Offer Type        : ' + @VendorOfferType + '</br>
							<br>   Offer Date        : ' + convert(varchar(30) , @VendorOfferDate,120) + '</br>
							<br><b>=======================================</b></br>

							<br><br>

							<b>ERROR !!!!!</b> Vmanage File : <b>' + @VendorFileName + '</b> does not exist
				
					</body>
			</html>'

			set @SubjectLine = 'VMANAGE : ERROR :  File for processed offerID : ' + convert(varchar(100) , @VendorOfferID) + ' with Reference No : ' + @VendorReferenceNo

			set @AbsoluteVendorFileName = NULL

			GOTO PUBLISHEMAIL

End


------------------------------------------------------------------------------------------
-- Set the Message and Subject line for the email to be send to the NEXWAVE resource
------------------------------------------------------------------------------------------

set @ErrorMsgStr = 
'<html
		<body>
				<br><b>===================================</b></br>
				<br><b> VENDOR OFFER INFO                  </b></br>
				<br><b>====================================</b></br>
				<br>   Vendor Offer ID   : ' + convert(varchar(100) , @VendorOfferID) + '</br>
				<br>   Reference NO      : ' + @VendorReferenceNo + '</br>
				<br>   Account           : ' + @Account + '</br>
				<br>   Offer Type        : ' + @VendorOfferType + '</br>
				<br>   Offer Date        : ' + convert(varchar(30) , @VendorOfferDate,120) + '</br>
				<br><b>=======================================</b></br>

				<br><br>

				<b>SUCCESS !!!!!</b> Vmanage File : <b>' + @VendorFileName + '</b> attached in the mail

				
		</body>
</html>'

set @SubjectLine = 'VMANAGE : SUCCESS : File for processed offerID : ' + convert(varchar(100) , @VendorOfferID) + ' with Reference No : ' + @VendorReferenceNo


PUBLISHEMAIL:

Select @SubjectLine , @EmailAddress, @AbsoluteVendorFileName

print @ErrorMsgStr

----------------------------------------------------------------------------------
-- Send the email to the NEXWAVE users post compilation of all the information
-----------------------------------------------------------------------------------


Exec msdb.dbo.sp_send_dbmail
@recipients = @EmailAddress,
@body= @ErrorMsgStr,
@subject = @SubjectLine,
@body_format = 'HTML',
@file_attachments= @AbsoluteVendorFileName ;
GO
