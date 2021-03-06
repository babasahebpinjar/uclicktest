USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetVendorOfferDetails]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetVendorOfferDetails]
(
     @VendorOfferID int
)
--With Encryption
As

-------------------------------------------
-- Initialize Variables for processing
-------------------------------------------

Declare @OfferStatusID int,
        @StatusTransitionFlag int = 0,
	@ValidateOfferTestMode int = 0,
	@ReferenceNo varchar(50),
        @OfferType varchar(20),
	@ReferenceFolderName  varchar(100),
	@OfferDate datetime,
	@DateFolderName varchar(50),
	@FileExists int

Select @OfferStatusID = tbl1.OfferStatusId,
       @ReferenceNo = tbl2.ReferenceNo,
       @OfferType = tbl3.Code,
       @OfferDate = tbl1.OfferReceiveDate
from tb_vendorOfferdetails tbl1
inner join tb_vendorReferenceDetails tbl2 on tbl1.ReferenceId = tbl2.ReferenceID
inner join tbloffertype tbl3 on tbl1.offertypeid = tbl3.ID
where vendorofferid = @VendorOfferID

if exists ( select 1 from tb_offerstatusworkflow where FromVendorOfferStatusID = @OfferStatusID and TransitionFlag = 1 )
	Set @StatusTransitionFlag = 1


if ( @OfferStatusID =  1 ) -- Registered
	Set @ValidateOfferTestMode = 1


---------------------------------------------------------------
-- Extract the path of Log File Name and populate if the log
-- file exists
---------------------------------------------------------------

Declare @LogFileName varchar(1000),
        @AbsoluteLogFilePath varchar(1000),
	@VendorOfferDirectory varchar(500),
	@cmd varchar(2000)

set @LogFileName = 'VendorOffer('+ convert(varchar(20) , @VendorOfferID) + ')_ProcessDetails.Log'

-----------------------------------------------------------------
-- STEP 1:
-- Get the VendorOfferDirectory config value from config table
------------------------------------------------------------------

Select @VendorOfferDirectory = ConfigValue
from TB_Config
where Configname = 'VendorOfferDirectory'

if ( @VendorOfferDirectory is NULL )
Begin

	set @VendorOfferDirectory = ''
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
					 'The network path was not found.',
					 'Access is denied.',
					 'File Not Found'
				       )								
          )		
Begin  

	set @VendorOfferDirectory = ''

End


drop table #tempCommandoutput

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

set @AbsoluteLogFilePath = @VendorOfferDirectory + @DateFolderName + '\' + @ReferenceFolderName + '\' + @LogFileName

set @FileExists = 0

Exec master..xp_fileexist @AbsoluteLogFilePath , @FileExists output  

if ( @FileExists <> 1 )
Begin

   set @LogFileName = NULL

End 

Else
Begin

	GOTO DISPLAYRESULT

End

----------------------------------------------
-- Case When the Offer File has been archived
----------------------------------------------

set @LogFileName = 'VendorOffer('+ convert(varchar(20) , @VendorOfferID) + ')_ProcessDetails.Log'

select @DateFolderName = 
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
	  end +  convert(varchar(4) , year(@OfferDate)) + '\' +
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

set @AbsoluteLogFilePath = @VendorOfferDirectory + 'Archive' + '\' + @DateFolderName + '\' + @ReferenceFolderName + '\' + @LogFileName

set @FileExists = 0

Exec master..xp_fileexist @AbsoluteLogFilePath , @FileExists output  

if ( @FileExists <> 1 )
Begin

   set @LogFileName = NULL

End 


DISPLAYRESULT:

select tbl1.VendorOfferID , tbl2.ReferenceNo ,tbl1.ReferenceID , tbl1.OfferFileName , tbl1.LoadOfferName, tbl1.OfferReceiveDate,
       tbl1.OfferTypeID , tbl3.Code as OfferTypename, tbl1.OfferProcessDate, tbl1.OfferStatusId , tbl4.OfferStatus , tbl1.AcknowledgementSend,
       tbl1.ProcessedStatusSend, tbl1.UploadOfferTypeID, tbl5.Code as UploadOfferTypename, tbl1.PartialOfferProcessflag, tbl1.ValidatedOfferFileName,
       @LogFileName as LogFileName, @StatusTransitionFlag as StatusTransitionFlag , @ValidateOfferTestMode as ValidateOfferTestMode,
       tbl1.ModifiedDate , tbl6.Name
from tb_vendorofferdetails tbl1
inner join tb_vendorReferenceDetails tbl2 on tbl1.ReferenceID = tbl2.ReferenceID
inner join tbloffertype tbl3 on tbl1.offertypeid = tbl3.ID
inner join tb_offerStatus tbl4 on tbl1.OfferStatusID = tbl4.OfferStatusID
left  join tbloffertype tbl5 on tbl1.uploadoffertypeid = tbl5.ID
left join tb_users tbl6 on tbl1.modifiedbyid = tbl6.userid
where tbl1.VendorOfferID = @VendorOfferID


GO
