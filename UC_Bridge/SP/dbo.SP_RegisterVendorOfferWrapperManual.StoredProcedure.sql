USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_RegisterVendorOfferWrapperManual]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_RegisterVendorOfferWrapperManual]
(
   @FolderName varchar(100),
   @FileName varchar(200),
   @OfferReceiveDate datetime,
   @VendorOfferID int output
   
)
--With Encryption
As

Declare @VendorOfferDirectory varchar(500),
        @OfferType varchar(20),
        @Command varchar(1000),
        @ErrorMsgStr varchar(max),
        @cmd varchar(2000),
        @FileExists int,
        @VendorOfferFileName varchar(1000),
        @RegisteredDirectoryName varchar(200),
        @ResponseFileName varchar(500)
	
------------------------------------------------------------------
-- Get the VendorOfferDirectory config value from config table
------------------------------------------------------------------

Select @VendorOfferDirectory = ConfigValue
from TB_Config
where Configname = 'VendorOfferDirectory'

if ( @VendorOfferDirectory is NULL )
Begin

       set @ErrorMsgStr = 'Error!!! Vendor Offer Directory configuration is not defined'
       Raiserror('%s' , 16 , 1, @ErrorMsgStr)
       return 1

End

----------------------------------------------------------------------
-- Convert the Offer Receive Date into the name of the Date Folder
----------------------------------------------------------------------

Declare @DateFolderName varchar(50)

select @DateFolderName = 
      convert(varchar(2) , day(@OfferReceiveDate ) ) +
      case month(@OfferReceiveDate)
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
      convert(varchar(4) , year(@OfferReceiveDate ) ) + '\'

        
if ( RIGHT(@VendorOfferDirectory , 1) <> '\' )
    set  @VendorOfferDirectory = @VendorOfferDirectory + '\'
    
set @VendorOfferFileName = @VendorOfferDirectory + @DateFolderName + @FolderName + '\' + @FileName
set @VendorOfferDirectory = @VendorOfferDirectory + @DateFolderName + @FolderName
set @RegisteredDirectoryName = @FolderName + '_Registered'

select @VendorOfferFileName as VendorOfferFileName,
       @VendorOfferDirectory as VendorOfferDirectory
    
---------------------------------------------------------------
-- Check that the directory and the vendor offer files exist 
---------------------------------------------------------------

create table #tempCommandoutput
(
  CommandOutput varchar(500)
)

set @cmd = 'dir ' + '"' + @VendorOfferDirectory + '"' + '/b'

insert into #tempCommandoutput
	Exec master..xp_cmdshell @cmd
	

if exists ( select 1 from #tempCommandoutput where CommandOutput = 'The system cannot find the file specified.'  )
Begin  
       set @ErrorMsgStr = 'Error!!! Vendor Offer Directory ' + @VendorOfferDirectory + ' does not exist or is invalid'
       Raiserror('%s' , 16 , 1, @ErrorMsgStr)
       Drop table #tempCommandoutput
       return 1
End

if exists ( select 1 from #tempCommandoutput where CommandOutput = 'The system cannot find the path specified.'  )
Begin
       set @ErrorMsgStr = 'Error!!! Vendor Offer Directory ' + @VendorOfferDirectory  + ' does not exist or is invalid'
       Raiserror('%s' , 16 , 1, @ErrorMsgStr)
       Drop table #tempCommandoutput
       return 1
End

if exists ( select 1 from #tempCommandoutput where CommandOutput = 'The network path was not found.'  )
Begin
       set @ErrorMsgStr = 'Error!!! Vendor Offer Directory ' + @VendorOfferDirectory + ' does not exist or is invalid'
       Raiserror('%s' , 16 , 1, @ErrorMsgStr)
       Drop table #tempCommandoutput
       return 1
End

if not exists (
                select 1
                from #tempCommandoutput
                where LTRIM(rtrim(CommandOutput)) = @FileName
              )
Begin

   set @ErrorMsgStr = 'Error !!!  Vendor Offer File : ' + @VendorOfferFileName + ' does not exist '
   Raiserror('%s',16,1,@ErrorMsgStr)
   Drop table #tempCommandoutput
   return 1

End              

Drop table #tempCommandoutput

-------------------------------------------------------
-- Extract the essential parameters for registering the
-- offer
--------------------------------------------------------   

set @OfferType = SUBSTRING( @FolderName , LEN(@FolderName) - 1, 2)
set @FolderName = substring(REPLACE(@FolderName , '_' , '/') , 1 , LEN(REPLACE(@FolderName , '_' , '/')) - 3 )

select @OfferType
select @FolderName

if exists ( select 1 from TB_VendorReferenceDetails where ReferenceNo = @FolderName )
Begin

	if not exists ( 
	             select 1 from TB_VendorOfferDetails tbl1
	             inner join TB_VendorReferenceDetails tbl2 on tbl1.Referenceid = tbl2.ReferenceID
	             where OfferFileName = @FileName 
	             and OfferReceiveDate = @OfferReceiveDate
	             and ReferenceNo = @FolderName
	             and OfferStatus in ( 'Registered' , 'Validated' , 'Process Error')
	             and OfferType = @OfferType
	          )	 
	Begin

            set @ResponseFileName  = @VendorOfferDirectory + '\PublishMessage.txt'
                         
			Exec SP_VendorOfferRegister @FolderName , @FileName , @OfferReceiveDate, @OfferType , @ResponseFileName , @VendorOfferID output

			if ( @VendorOfferID is not NULL )
			Begin

				---------------------------------------------------------------------
				-- Incase the registration happened successfully, then send an email
				-- if the reference for the offer is configured for manual validation
				----------------------------------------------------------------------

				if exists ( select 1 from TB_VendorReferenceDetails where ReferenceNo = @FolderName and AutoOfferUploadFlag = 0 )
				Begin

					Declare @EmailAddress Varchar(2000),
					        @SubjectLine Varchar(2000),
						    @MessageStr varchar(5000),
							@Account varchar(100),
							@ReferenceNo varchar(100),
							@OfferDate datetime


                    select  @Account = tbl1.Account,
					        @ReferenceNo = tbl1.ReferenceNo,
							@OfferType = tbl2.OfferType,
							@OfferDate = tbl2.OfferReceiveDate
                    from TB_VendorReferenceDetails tbl1
					inner join TB_VendorOfferDetails tbl2 on tbl1.ReferenceID= tbl2.Referenceid
					where tbl2.VendorOfferID = @VendorOfferID

					set @MessageStr = '======================================================' + '<br>' +
									  '					<b> VENDOR OFFER INFO </b>			 ' + '<br>' +
									  '======================================================' + '<br>' +
									  '<b>Account         :</b> ' + @Account  + '<br>'+
									  '<b>Reference       :</b> ' + @ReferenceNo + '<br>'+                  
									  '<b>Offer Type      :</b> ' + @OfferType + '<br>'+  
									  '<b>Offer Date      :</b> ' + convert(varchar(30) , @OfferDate, 100) +'<br>' +
									  '======================================================' + '<br>' + '<br>'


					Select @EmailAddress = ConfigValue
					from TB_Config
					where Configname = 'RegisterOfferAlertEmailAddress'

					if (@EmailAddress is not null)
					Begin

						set @SubjectLine = 'OFFER REGISTRATION : ' + @FolderName + ' : '+ convert(varchar(10) , @OfferReceiveDate , 101) + ' : '+ @OfferType
						
						set @MessageStr = @MessageStr + '<b>Offer file by the name : ('+ @FileName + ') has been registered with Vendor Offer with ID : ('+ convert(varchar(20) , @VendorOfferID)+')</b>'+
								  '<br><br>'+
								  '<b>The offer is configured for manual validation. Please proceed with Validation.</b>'


                         Exec SP_SendEmailAlerts @EmailAddress, @SubjectLine, @MessageStr , NULL
						

					End
					

				End

			End
			
			Else
			Begin

				set @ErrorMsgStr = 'ERROR !!!  Vendor Offer File : ' + @FileName  + ' has not been REGISTERED in the system due to exception.'
				Raiserror('%s',16,1,@ErrorMsgStr)
				return 1
				 

			End
	
	End

        Else
        Begin

   		set @ErrorMsgStr = 'ERROR !!!  Vendor Offer File : ' + @FileName  + ' has already been REGISTERED in the system.'
   		Raiserror('%s',16,1,@ErrorMsgStr)
   		return 1
                 

        End
	

End

else
Begin

	set @ErrorMsgStr = 'ERROR !!! Reference No : ' + @FolderName + ' provided for registering the offer does not exist.'
	Raiserror('%s',16,1,@ErrorMsgStr)
	return 1
                 

End

Return 0

GO
