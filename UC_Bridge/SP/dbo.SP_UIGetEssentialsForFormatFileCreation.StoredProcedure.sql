USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetEssentialsForFormatFileCreation]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetEssentialsForFormatFileCreation]
(
    @FormatFileName varchar(200),
    @VendorOfferFormat varchar(50),
    @MultipleSheetsInOffer int
)
--With Encryption
As


Declare @DefualtTemplatePath varchar(500),
        @TargetFormatFilePath varchar(500),
	@ErrorDescription varchar(500),
	@cmd varchar(2000)

---------------------------------------------------------------
-- Get the main directory for Vendor Offer upload deployment
---------------------------------------------------------------

Declare @FormatTemplateDirectory varchar(500)

Select @FormatTemplateDirectory  = ConfigValue
from TB_Config
where Configname = 'FormatTemplateDirectory'

if (@FormatTemplateDirectory is NULL)
Begin

	set @ErrorDescription = 'Error !!! Basic Configuration Missing.There is no value defined for config parameter FormatTemplateDirectory'
	GOTO RETURNDATA
End

if ( right(@FormatTemplateDirectory,1) <> '\')
    set @FormatTemplateDirectory = @FormatTemplateDirectory + '\'

---------------------------------------------------------
-- Find out the default template which needs to be used
-- for creating format file
---------------------------------------------------------

Declare @TemplateFileName varchar(200),
	@FileExists int

select @TemplateFileName = TemplateFileName
from tb_VOT
where VendorOfferFormat = @VendorOfferFormat
and MultipleSheetsInOffer = @MultipleSheetsInOffer

if (@TemplateFileName is NULL)
Begin

	set @ErrorDescription = 'Error !!! No template defined for vendor offers of type ' + @VendorOfferFormat + ' having '+
	                        Case
					When @MultipleSheetsInOffer = 1 then 'multiple offer sheets' 
					When @MultipleSheetsInOffer = 0 then 'single offer sheet' 
				End
	GOTO RETURNDATA
End

set @DefualtTemplatePath = @FormatTemplateDirectory +  @TemplateFileName

--------------------------------------------
-- Check if the Template File exists or not
--------------------------------------------

set @FileExists = 0

Exec master..xp_fileexist @DefualtTemplatePath , @FileExists output  

if ( @FileExists <> 1 )
Begin

        
	set @ErrorDescription = 'Error !!! Template file (' + @DefualtTemplatePath + ') does not exist. Please check the configuration'
	set @DefualtTemplatePath = NULL
	GOTO RETURNDATA

End 



------------------------------------------------------------
-- Get the complete file name with path, which will be used
-- to store the newly created format file
------------------------------------------------------------

Declare @ParseConfigDirectory  varchar(500)

Select @ParseConfigDirectory  = ConfigValue
from TB_Config
where Configname = 'ParseConfigDirectory'


if (@ParseConfigDirectory is NULL)
Begin

	set @ErrorDescription = 'Error !!! Basic Configuration Missing.There is no value defined for config parameter ParseConfigDirectory'
	GOTO RETURNDATA
End

if ( right(@ParseConfigDirectory,1) <> '\')
    set @ParseConfigDirectory = @ParseConfigDirectory + '\'

------------------------------------------------------------
-- Check if the directory to hold the format files exist
-- or not
------------------------------------------------------------

create table #tempCommandoutput
(
  CommandOutput varchar(500)
)

set @cmd = 'dir ' + '"' + @ParseConfigDirectory  + '"' + '/b'
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
	set @ErrorDescription = 'Error !!! Directory ('+ @ParseConfigDirectory + ') to hold format files does not exist or is not accessible'
	Drop Table #tempCommandoutput
	GOTO RETURNDATA
End

Drop Table #tempCommandoutput

set @TargetFormatFilePath = @ParseConfigDirectory + @FormatFileName + '.Fmt'


RETURNDATA:

select @DefualtTemplatePath as DefualtTemplatePath,
       @TargetFormatFilePath   as TargetFormatFilePath,
       @ErrorDescription as ErrorDescription
GO
