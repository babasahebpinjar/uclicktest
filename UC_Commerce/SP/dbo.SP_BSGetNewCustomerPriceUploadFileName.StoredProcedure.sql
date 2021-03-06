USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSGetNewCustomerPriceUploadFileName]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[SP_BSGetNewCustomerPriceUploadFileName]
(
	@FileName varchar(500) Output,
	@CompleteFileName varchar(1000) Output,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

---------------------------------------------------------------
--  Get the Working directory for Customer Price Upload File
---------------------------------------------------------------

Declare @AbsoluteFilePath varchar(1000),
		@CPUOfferDirectory varchar(500),
		@cmd varchar(2000)


Select @CPUOfferDirectory = ConfigValue
from UC_Admin.dbo.TB_Config
where Configname = 'CustomerPriceUploadWorkingDirectory'
and AccessScopeID = -6

if ( @CPUOfferDirectory is NULL )
Begin
	
	set @ResultFlag = 1
	set @ErrorDescription = 'ERROR !!!! The configuration for Customer Price Upload Path (CustomerPriceUploadWorkingDirectory) is missing'
	set @FileName = NULL
	set @CompleteFileName = NULL
	GOTO ENDPROCESS 

End

if ( RIGHT(@CPUOfferDirectory , 1) <> '\' )
     set @CPUOfferDirectory = @CPUOfferDirectory + '\'

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempCommandoutput') )
	Drop table #tempCommandoutput

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

	set @ResultFlag = 1
	set @ErrorDescription = 'ERROR !!!! The Customer Price Upload Path : ( ' + @CPUOfferDirectory + ' )  is incorrect or does not exist'
	set @FileName = NULL
	set @CompleteFileName = NULL
	GOTO ENDPROCESS 

End


----------------------------------------------------------------
-- Prepare the internal name for the Customer Price Upload File
----------------------------------------------------------------

set @FileName = 'CustomerPriceUpload_' + replace(replace(replace(convert(varchar(50) , getdate() , 120) , '-', ''), ' ', ''), ':' , '') + '.txt'
set @CompleteFileName = @CPUOfferDirectory + @FileName

ENDPROCESS:

if exists (select 1 from tempdb.dbo.sysobjects where xtype = 'U' and id = object_id(N'tempdb..#tempCommandoutput') )
	Drop table #tempCommandoutput

GO
