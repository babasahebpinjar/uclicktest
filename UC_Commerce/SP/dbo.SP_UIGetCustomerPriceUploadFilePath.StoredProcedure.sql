USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetCustomerPriceUploadFilePath]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetCustomerPriceUploadFilePath]
(
    @CustomerPriceUploadID int,
    @FileType int,
    @CompleteFileName varchar(1000) Output
)
--With Encryption
As

-------------------------------------------
-- Initialize Variables for processing
-------------------------------------------

Declare	@FileExists int,
		@CustomerPriceFileName varchar(500),
		@LogFileName varchar(500)

if (( @FileType is NULL ) or ( @FileType not in (1,2) ) )
Begin

	set @CompleteFileName = NULL
	return

End


Select @CustomerPriceFileName = tbl1.CustomerPriceFileName,
       @LogFileName = Replace(tbl1.CustomerPriceFileName , '.txt' , '.log')
from tb_CustomerPriceUpload tbl1
where CustomerPriceUploadID = @CustomerPriceUploadID

--select @CustomerPriceFileName , @LogFileName

---------------------------------------------------------------
-- Extract the path of Log File Name and populate if the log
-- file exists
---------------------------------------------------------------

Declare @AbsoluteFilePath varchar(1000),
		@CPUOfferDirectory varchar(500),
		@cmd varchar(2000)


-----------------------------------------------------------------
-- Get the VendorOfferWorkingDirectory config value from config table
------------------------------------------------------------------

Select @CPUOfferDirectory = ConfigValue
from UC_Admin.dbo.TB_Config
where Configname = 'CustomerPriceUploadWorkingDirectory'
and AccessScopeID = -6

if ( @CPUOfferDirectory is NULL )
Begin

	set @CPUOfferDirectory = ''
End

if ( RIGHT(@CPUOfferDirectory , 1) <> '\' )
     set @CPUOfferDirectory = @CPUOfferDirectory + '\'


create table #tempCommandoutput
(
  CommandOutput varchar(500)
)

set @cmd = 'dir ' + '"' + @CPUOfferDirectory + '"' + '/b'
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

	set @CPUOfferDirectory = ''

End


drop table #tempCommandoutput


if (@FileType = 1 ) -- Offer File Name
	set @AbsoluteFilePath = @CPUOfferDirectory + '\' + @CustomerPriceFileName

if (@FileType = 2 ) -- Log File Name
	set @AbsoluteFilePath = @CPUOfferDirectory + 'Log' + '\' + @LogFileName


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
