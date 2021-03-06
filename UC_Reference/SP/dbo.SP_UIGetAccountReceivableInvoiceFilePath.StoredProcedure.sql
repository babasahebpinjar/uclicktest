USE [UC_Reference]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetAccountReceivableInvoiceFilePath]    Script Date: 5/2/2020 6:28:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetAccountReceivableInvoiceFilePath]
(
    @AccountReceivableID int,
    @CompleteFileName varchar(1000) Output,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
--With Encryption
As

set @ErrorDescription = NULL
set @ResultFlag = 0

-------------------------------------------
-- Initialize Variables for processing
-------------------------------------------

Declare	@FileExists int,
		@PhysicalInvoiceFileName varchar(500)


Select @PhysicalInvoiceFileName = PhysicalInvoice
from tb_AccountReceivable tbl1
where AccountReceivableID = @AccountReceivableID

-- Debug Start
-- select @PhysicalInvoiceFileName 
-- Debug End

---------------------------------------------------------------
-- Extract the path of invoice File Name and populate if the 
-- file exists
---------------------------------------------------------------

Declare @AbsoluteFilePath varchar(1000),
		@PhysicalInvoiceDirectory varchar(500),
		@cmd varchar(2000)

-----------------------------------------------------------------
-- Get the Physical Invoice Directory config value from config table
------------------------------------------------------------------

Select @PhysicalInvoiceDirectory = ConfigValue
from UC_Admin.dbo.tb_Config
where Configname = 'AdvancePaymentInvoiceDirectory'
and AccessScopeID = -4

if ( @PhysicalInvoiceDirectory is NULL )
Begin

	set @ErrorDescription = 'ERROR !!!! The Physical Invoice Directory in not configured in the system (AdvancePaymentInvoiceDirectory)'
	set @ResultFlag = 1
	set @CompleteFileName = NULL
	return 1

End

if ( RIGHT(@PhysicalInvoiceDirectory , 1) <> '\' )
     set @PhysicalInvoiceDirectory = @PhysicalInvoiceDirectory + '\'


create table #tempCommandoutput
(
  CommandOutput varchar(500)
)

set @cmd = 'dir ' + '"' + @PhysicalInvoiceDirectory + '"' + '/b'
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


	set @ErrorDescription = 'ERROR !!!! The Physical Invoice Directory ('+@PhysicalInvoiceDirectory+')' + ' is in not accessible '
	set @ResultFlag = 1
	set @CompleteFileName = NULL
	return 1

End

-- Debug Start
--select * from #tempCommandoutput
-- Debug End


drop table #tempCommandoutput

set @AbsoluteFilePath = @PhysicalInvoiceDirectory  + @PhysicalInvoiceFileName


-- Debug Start
--select @AbsoluteFilePath
-- Debug End

set @FileExists = 0

Exec master..xp_fileexist @AbsoluteFilePath , @FileExists output  

if ( @FileExists <> 1 )
Begin

	set @ErrorDescription = 'ERROR !!!! The Physical invoice does not exist in the download folder. Please regenerate and try again to download.'
	set @ResultFlag = 1
	set @CompleteFileName = NULL
	return 1

End 

Else
Begin

   set @CompleteFileName = @AbsoluteFilePath

End 

return 0
GO
