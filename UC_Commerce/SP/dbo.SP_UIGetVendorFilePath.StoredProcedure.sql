USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetVendorFilePath]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_UIGetVendorFilePath]
(
    @OfferID int,
    @FileType int,
    @CompleteFileName varchar(1000) Output
)
--With Encryption
As

-------------------------------------------
-- Initialize Variables for processing
-------------------------------------------

Declare	@FileExists int,
		@OfferFileName varchar(500),
		@LogFileName varchar(500)

if (( @FileType is NULL ) or ( @FileType not in (1,2) ) )
Begin

	set @CompleteFileName = NULL
	return

End


Select @OfferFileName = tbl1.OfferFileName,
       @LogFileName = Replace(tbl1.OfferFileName , '.offr' , '.log')
from tb_Offer tbl1
where offerid = @OfferID

--select @OfferFileName , @LogFileName

---------------------------------------------------------------
-- Extract the path of Log File Name and populate if the log
-- file exists
---------------------------------------------------------------

Declare @AbsoluteFilePath varchar(1000),
		@VendorOfferDirectory varchar(500),
		@cmd varchar(2000)


-----------------------------------------------------------------
-- Get the VendorOfferWorkingDirectory config value from config table
------------------------------------------------------------------

Select @VendorOfferDirectory = ConfigValue
from UC_Admin.dbo.TB_Config
where Configname = 'VendorOfferWorkingDirectory'
and AccessScopeID = -6

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


if (@FileType = 1 ) -- Offer File Name
	set @AbsoluteFilePath = @VendorOfferDirectory + '\' + @OfferFileName

if (@FileType = 2 ) -- Log File Name
	set @AbsoluteFilePath = @VendorOfferDirectory + 'Log' + '\' + @LogFileName


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
