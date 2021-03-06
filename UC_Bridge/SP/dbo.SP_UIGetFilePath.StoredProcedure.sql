USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetFilePath]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetFilePath]
(
    @VendorOfferID int,
    @FileType int,
    @CompleteFileName varchar(1000) Output
)
--With Encryption
As

-------------------------------------------
-- Initialize Variables for processing
-------------------------------------------

Declare @OfferStatusID int,
	@ReferenceNo varchar(50),
        @OfferType varchar(20),
	@ReferenceFolderName  varchar(100),
	@OfferDate datetime,
	@DateFolderName varchar(50),
	@FileExists int,
	@ValidatedOfferFileName varchar(500),
	@OfferFileName varchar(500),
	@LogFileName varchar(500)

if (( @FileType is NULL ) or ( @FileType not in (1,2,3) ) )
Begin

	set @CompleteFileName = NULL
	return

End

Select @OfferStatusID = tbl1.OfferStatusId,
       @ReferenceNo = tbl2.ReferenceNo,
       @OfferType = tbl3.Code,
       @OfferDate = tbl1.OfferReceiveDate,
       @OfferFileName = tbl1.OfferFileName,
       @ValidatedOfferFileName = ValidatedOfferFileName,
       @LogFileName = 'VendorOffer('+ convert(varchar(20) , @VendorOfferID) + ')_ProcessDetails.Log'
from tb_vendorOfferdetails tbl1
inner join tb_vendorReferenceDetails tbl2 on tbl1.ReferenceId = tbl2.ReferenceID
inner join tbloffertype tbl3 on tbl1.offertypeid = tbl3.ID
where vendorofferid = @VendorOfferID

--select @OfferFileName , @ValidatedOfferFileName , @LogFileName

---------------------------------------------------------------
-- Extract the path of Log File Name and populate if the log
-- file exists
---------------------------------------------------------------

Declare @AbsoluteFilePath varchar(1000),
	@VendorOfferDirectory varchar(500),
	@cmd varchar(2000)


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

if (@FileType = 1 ) -- Offer File Name
	set @AbsoluteFilePath = @VendorOfferDirectory + @DateFolderName + '\' + @ReferenceFolderName + '\' + @OfferFileName

if (@FileType = 2 ) -- Log File Name
	set @AbsoluteFilePath = @VendorOfferDirectory + @DateFolderName + '\' + @ReferenceFolderName + '\' + @LogFileName

if (@FileType = 3 ) -- Validated File Name
Begin
        if (@ValidatedOfferFileName is NULL)
	Begin
		set @CompleteFileName = NULL
		return
	End

	Else
	Begin
		set @AbsoluteFilePath = @VendorOfferDirectory + @DateFolderName + '\' + @ReferenceFolderName + '\' + @ValidatedOfferFileName

	End

End

--select @AbsoluteFilePath

set @FileExists = 0

Exec master..xp_fileexist @AbsoluteFilePath , @FileExists output  

if ( @FileExists <> 1 )
Begin

   set @CompleteFileName = NULL

End 

Else
Begin

   set @CompleteFileName = @AbsoluteFilePath
   return

End 


----------------------------------------------
-- Case When the Offer File has been archived
----------------------------------------------

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
	  end + convert(varchar(4) , year(@OfferDate)) + '\' +
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

if (@FileType = 1 ) -- Offer File Name
	set @AbsoluteFilePath = @VendorOfferDirectory + 'Archive' + '\' + @DateFolderName + '\' + @ReferenceFolderName + '\' + @OfferFileName

if (@FileType = 2 ) -- Log File Name
	set @AbsoluteFilePath = @VendorOfferDirectory + 'Archive' + '\' + @DateFolderName + '\' + @ReferenceFolderName + '\' + @LogFileName

if (@FileType = 3 ) -- Validated File Name
Begin
        if (@ValidatedOfferFileName is NULL)
	Begin
		set @CompleteFileName = NULL
		return
	End

	Else
	Begin
		set @AbsoluteFilePath = @VendorOfferDirectory + 'Archive' + '\' + @DateFolderName + '\' + @ReferenceFolderName + '\' + @ValidatedOfferFileName

	End

End

--select @AbsoluteFilePath

set @FileExists = 0

Exec master..xp_fileexist @AbsoluteFilePath , @FileExists output  

if ( @FileExists <> 1 )
Begin

   set @CompleteFileName = NULL

End 

Else
Begin

   set @CompleteFileName = @AbsoluteFilePath

End 


return
GO
