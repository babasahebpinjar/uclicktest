USE [UC_Commerce]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSParseVendorOfferFile]    Script Date: 5/2/2020 6:18:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSParseVendorOfferFile]
(
    @SourceID int,
	@ExternalOfferFileName varchar(1000),
	@CompleteParseOfferFileName varchar(1000) Output,
	@ParseOfferLogFileName varchar(1000) Output,
	@ResultFlag int output,
	@ErrorDescription varchar(2000) output
)
As


Declare @FileExists int,
		@cmd varchar(2000),
		@ParseOfferFileName varchar(500),
		@VendorOfferLogDirectory varchar(1000)

set @ResultFlag = 0
set @ErrorDescription = NULL


-------------------------------------------------------------------------------
-- Check to see that the SourceID exists in the system and is not a NULL value
-------------------------------------------------------------------------------

if (@SourceID is NULL)
Begin

	set @ErrorDescription = 'ERROR !!! SourceID cannot be a NULL value'
	set @ResultFlag = 1
	Return 1

End

if not exists ( select 1 from tb_source where sourceID = @SourceID and SourceTypeID = -1 )  -- Source of the type Vendor
Begin

	set @ErrorDescription = 'ERROR !!! SourceID does not exist in the system'
	set @ResultFlag = 1
	Return 1

End

------------------------------------------------------
-- Check to ensure that the file exists in the system
------------------------------------------------------

set @FileExists = 0

Exec master..xp_fileexist @ExternalOfferFileName , @FileExists output  

if ( @FileExists <> 1 )
Begin

	set @ErrorDescription = 'ERROR !!! Offer file with the name  and path : (' + @ExternalOfferFileName + ') does not exist or is not accessible'
	set @ResultFlag = 1
	Return 1	

End 

------------------------------------------------------------------------------
-- Extract the essential vendor offer processing parameters from config tables
------------------------------------------------------------------------------

Declare @VendorOfferParseFile varchar(1000),
        @VendorOfferParseConfigFile varchar(1000),
		@VendorOfferWorkingDirectory varchar(1000)


------------------------------------
-- Vendor Offer Working Directory
------------------------------------

select @VendorOfferWorkingDirectory = configvalue
from UC_Admin.dbo.tb_Config
where ConfigName = 'VendorOfferWorkingDirectory'
and AccessScopeID = -6

if (@VendorOfferWorkingDirectory is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! System configuration parameter "VendorOfferWorkingDirectory" not defined'
	set @ResultFlag = 1
	Return 1

End

----------------------------------------------
-- Check if the directory exists and is valid
----------------------------------------------

if ( RIGHT(@VendorOfferWorkingDirectory , 1) <> '\' )
     set @VendorOfferWorkingDirectory = @VendorOfferWorkingDirectory + '\'


create table #tempCommandoutput
(
  CommandOutput varchar(500)
)

set @cmd = 'dir ' + '"' + @VendorOfferWorkingDirectory + '"' + '/b'
--print @cmd

insert into #tempCommandoutput
	Exec master..xp_cmdshell @cmd
	

if exists ( 
		select 1 from #tempCommandoutput
		where CommandOutput in (
					 'The system cannot find the file specified.',
					 'The system cannot find the path specified.',
					 'The network path was not found.'
				       )								
          )		
Begin  
       set @ErrorDescription = 'Error!!! Vendor Offer Working Directory ' + @VendorOfferWorkingDirectory + ' does not exist or is invalid'
       set @ResultFlag = 1
       Drop table #tempCommandoutput
       return 1
End

------------------------------------
-- Vendor Offer Parse Config File
------------------------------------

select @VendorOfferParseConfigFile = configvalue
from UC_Admin.dbo.tb_Config
where ConfigName = 'VendorOfferParseConfigFile'
and AccessScopeID = -6

if (@VendorOfferParseConfigFile is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! System configuration parameter "VendorOfferParseConfigFile" not defined'
	set @ResultFlag = 1
	Return 1

End

------------------------------------------------------
-- Check to ensure that Vendor Offer Parse Config File
-- exists in the system
------------------------------------------------------

set @FileExists = 0

Exec master..xp_fileexist @VendorOfferParseConfigFile , @FileExists output  

if ( @FileExists <> 1 )
Begin

	set @ErrorDescription = 'ERROR !!! Application configuration file for parsing vendor offer : (' + @VendorOfferParseConfigFile + ') does not exist or is not accessible'
	set @ResultFlag = 1
	Return 1	

End


------------------------------------
-- Vendor Offer Parse File
------------------------------------

select @VendorOfferParseFile = configvalue
from UC_Admin.dbo.tb_Config
where ConfigName = 'VendorOfferParseFile'
and AccessScopeID = -6

if (@VendorOfferParseFile is NULL )
Begin

	set @ErrorDescription = 'ERROR !!! System configuration parameter "VendorOfferParseFile" not defined'
	set @ResultFlag = 1
	Return 1

End

------------------------------------------------------
-- Check to ensure that Vendor Offer Parse File
-- exists in the system
------------------------------------------------------

set @FileExists = 0

Exec master..xp_fileexist @VendorOfferParseFile , @FileExists output  

if ( @FileExists <> 1 )
Begin

	set @ErrorDescription = 'ERROR !!! Application file for parsing vendor offer : (' + @VendorOfferParseFile + ') does not exist or is not accessible'
	set @ResultFlag = 1
	Return 1	

End

------------------------------------------------------
-- Build the name of the Parsed Output file, that will
-- be registered in the system
------------------------------------------------------

Declare @Source varchar(60)

Select @Source = [Source]
from tb_Source
where sourceID = @SourceID

set @ParseOfferFileName = Replace(Replace(Replace(convert(varchar(30) ,getdate() , 120) , ' ' , '') , '-' , '') , ':' , '') + '_' + Replace(@Source , ' ' , '') + '.offr'
set @CompleteParseOfferFileName = @VendorOfferWorkingDirectory + @ParseOfferFileName

----------------------------------------------------
-- Delete file if it already exists in the system
----------------------------------------------------

set @FileExists = 0

Exec master..xp_fileexist @CompleteParseOfferFileName , @FileExists output  

if ( @FileExists = 1 )
Begin

   set @cmd = 'del ' + '"' + @CompleteParseOfferFileName + '"'
   Exec master..xp_cmdshell @cmd

End 

---------------------------------------------------------
-- Set up the location for the Parse offer Log File Name
---------------------------------------------------------

set @VendorOfferLogDirectory = @VendorOfferWorkingDirectory + 'Log\'

----------------------------------------------
-- Check if the directory exists and is valid
----------------------------------------------

if ( RIGHT(@VendorOfferLogDirectory , 1) <> '\' )
     set @VendorOfferLogDirectory = @VendorOfferLogDirectory + '\'


set @cmd = 'dir ' + '"' + @VendorOfferLogDirectory + '"' + '/b'
--print @cmd

delete from #tempCommandoutput

insert into #tempCommandoutput
	Exec master..xp_cmdshell @cmd
	

if exists ( 
		select 1 from #tempCommandoutput
		where CommandOutput in (
					 'The system cannot find the file specified.',
					 'The system cannot find the path specified.',
					 'The network path was not found.'
				       )								
          )		
Begin  
       set @ErrorDescription = 'Error!!! Vendor Offer log Directory ' + @VendorOfferLogDirectory + ' does not exist or is invalid'
       set @ResultFlag = 1
       Drop table #tempCommandoutput
       return 1
End

Drop table #tempCommandoutput

set @ParseOfferLogFileName = @VendorOfferLogDirectory + Replace(Replace(Replace(convert(varchar(30) ,getdate() , 120) , ' ' , '') , '-' , '') , ':' , '') + '_' + Replace(@Source , ' ' , '') + '.log'

------------------------------------------------------------
-- Delete the log file , if it already exists in the system
------------------------------------------------------------

set @FileExists = 0

Exec master..xp_fileexist @ParseOfferLogFileName , @FileExists output  

if ( @FileExists = 1 )
Begin

   set @cmd = 'del ' + '"' + @ParseOfferLogFileName + '"'
   Exec master..xp_cmdshell @cmd

End 

---------------------------------------------------------------
-- Call the script to parse the External offer file and
-- create the parse file for registration in system
---------------------------------------------------------------

select @VendorOfferParseFile as VendorOfferParseFile,
	   @ExternalOfferFileName as ExternalOfferFileName,
	@VendorOfferParseConfigFile as VendorOfferParseConfigFile,
	@CompleteParseOfferFileName as CompleteParseOfferFileName,
	@ParseOfferLogFileName as ParseOfferLogFileName

-------------------------------------------------------
-- Get the default folder for the Perl executable
-------------------------------------------------------

Declare @PerlExecutable varchar(500)

select @PerlExecutable = ConfigValue
from UC_Admin.dbo.tb_config
where configname = 'PerlExecutable'
and AccessScopeID = -1 -- General

if (@PerlExecutable is not NULL)
Begin

			set @cmd = 'ECHO ? && '+'"'+@PerlExecutable+'"' + ' '  + '"' + @VendorOfferParseFile + '"' + ' ' + '"' +  @ExternalOfferFileName + '"' + ' ' + '"' + @VendorOfferParseConfigFile + '"' + ' ' + '"' + @CompleteParseOfferFileName + '"' + ' ' + '"' + @ParseOfferLogFileName + '"'

End

Else
Begin

			set @cmd = 'perl ' + '"' + @VendorOfferParseFile + '"' + ' ' + '"' +  @ExternalOfferFileName + '"' + ' ' + '"' + @VendorOfferParseConfigFile + '"' + ' ' + '"' + @CompleteParseOfferFileName + '"' + ' ' + '"' + @ParseOfferLogFileName + '"'

End



--print @cmd

Exec master..xp_cmdshell @cmd

------------------------------------------------------
-- Post executiion check if the parsed file exists or 
-- not
-----------------------------------------------------

set @FileExists = 0

Exec master..xp_fileexist @CompleteParseOfferFileName , @FileExists output  

if ( @FileExists <> 1 )
Begin

        set @ErrorDescription = 'Error !!! Exception during parsing of offer file, as parsed file :( ' + @ParseOfferFileName + ' ) does not exist'
		set @ResultFlag = 1
		Return 1

End


Return 0




						  
GO
