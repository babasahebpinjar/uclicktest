USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetCustomerOfferSampleUploadFile]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_UIGetCustomerOfferSampleUploadFile]
(
    @CompleteDirectory varchar(1000) Output,
	@ErrorDescription varchar(2000) Output,
	@ResultFlag int Output
)
--With Encryption
As

set @ErrorDescription = NULL
set @ResultFlag = 0

---------------------------------------------------------------
-- Extract the path of Log File Name and populate if the log
-- file exists
---------------------------------------------------------------

Declare @CustomerOfferSampleUploadFile varchar(1000),
		@cmd varchar(2000),
		@FileExists int


-----------------------------------------------------------------
-- Get the CustomerOfferSampleUploadFile config value from config table
------------------------------------------------------------------

Select @CustomerOfferSampleUploadFile = ConfigValue
from UC_Admin.dbo.TB_Config
where Configname = 'CustomerOfferSampleUploadFile'
and AccessScopeID = -6

if (@CustomerOfferSampleUploadFile is null)
Begin

   set @ErrorDescription = 'ERROR !!! Config parameter CustomerOfferSampleUploadFile not defined for sample file'
   set @ResultFlag = 1
   return 1

End

set @FileExists = 0

Exec master..xp_fileexist @CustomerOfferSampleUploadFile , @FileExists output  

if ( @FileExists <> 1 )
Begin

   set @ErrorDescription = 'ERROR !!! Sample customer offer upload file does not exist'
   set @ResultFlag = 1
   return 1

End 

set @CompleteDirectory = @CustomerOfferSampleUploadFile

return 0

GO
