USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetCustomerOfferDirectory]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetCustomerOfferDirectory]
(
    @FileType int,
    @CompleteDirectory varchar(1000) Output,
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

if (( @FileType is NULL ) or ( @FileType not in (1,2,3) ) )
Begin

	set @CompleteDirectory = NULL
	set @ErrorDescription = 'Error !!! File Type needs to be either 1,2 or 3'
	set @ResultFlag = 1
	return 0

End


---------------------------------------------------------------
-- Extract the path of Log File Name and populate if the log
-- file exists
---------------------------------------------------------------

Declare @AbsoluteFilePath varchar(1000),
		@CustomerOfferDirectory varchar(500),
		@cmd varchar(2000)

-----------------------------------------------------------------
-- Get the VendorOfferWorkingDirectory config value from config table
------------------------------------------------------------------

Select @CustomerOfferDirectory = ConfigValue
from UC_Admin.dbo.TB_Config
where Configname =
          Case
		     When @FileType = 1 then 'CustomerOfferWorkingDirectory'
			 When @FileType = 2 then 'CustomerOfferLogDirectory'
			 When @FileType = 3 then 'ExternalCustomerOfferDirectory'
		  End 
and AccessScopeID = -6

if ( @CustomerOfferDirectory is NULL )
Begin

	set @CompleteDirectory = ''
	set @ErrorDescription = 'The configuration parameter : ' + 
	                        Case
								When @FileType = 1 then 'CustomerOfferWorkingDirectory'
								When @FileType = 1 then 'CustomerOfferLogDirectory'
								When @FileType = 1 then 'ExternalCustomerOfferDirectory'
							End + ' does not exist in the config table'
	set @ResultFlag = 1
	return 0
End

if ( RIGHT(@CustomerOfferDirectory , 1) <> '\' )
     set @CustomerOfferDirectory = @CustomerOfferDirectory + '\'


create table #tempCommandoutput
(
  CommandOutput varchar(500)
)

set @cmd = 'dir ' + '"' + @CustomerOfferDirectory + '"' + '/b'
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

    set @ErrorDescription = 'Error !!! Accessing the directory path : (' + @CustomerOfferDirectory + ')'
	set @CompleteDirectory = ''
	set @ResultFlag = 1

End

Else
Begin

		set @CompleteDirectory = @CustomerOfferDirectory

End

--select * from #tempCommandoutput


drop table #tempCommandoutput


return
GO
