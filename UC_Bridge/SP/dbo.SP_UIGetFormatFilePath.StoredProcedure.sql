USE [UC_Bridge]
GO
/****** Object:  StoredProcedure [dbo].[SP_UIGetFormatFilePath]    Script Date: 5/2/2020 6:45:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UIGetFormatFilePath]
(
	@FormatFileName varchar(200),
	@CompleteFilePath varchar(500) Output

)
--With Encryption
As

Declare @FileExists int,
        @cmd varchar(2000)


if (@FormatFileName is NULL)
Begin

       set @CompleteFilePath = NULL
       return 1

End

-----------------------------------------------------------------
-- Get the VendorOfferDirectory config value from config table
------------------------------------------------------------------

Declare @ParseConfigDirectory  varchar(500)

Select @ParseConfigDirectory  = ConfigValue
from TB_Config
where Configname = 'ParseConfigDirectory '

if ( @ParseConfigDirectory  is NULL )
Begin

       set @CompleteFilePath = NULL
       return 1

End

if ( RIGHT(@ParseConfigDirectory  , 1) <> '\' )
     set @ParseConfigDirectory  = @ParseConfigDirectory  + '\'


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
					 'The network path was not found.'
				       )								
          )		
Begin  
       set @CompleteFilePath = NULL
       Drop table #tempCommandoutput
       return 1
End



-------------------------------------------------------
-- Build the name of the parsing config file and check
-- if the same exists or not.
-------------------------------------------------------

Declare @ParseFileName varchar(500)

set @ParseFileName = @ParseConfigDirectory + @FormatFileName + '.Fmt'

--select @ParseConfigDirectory , @FormatFileName , @ParseFileName

set @FileExists = 0

Exec master..xp_fileexist @ParseFileName , @FileExists output  

if ( @FileExists <> 1 )
Begin

       set @CompleteFilePath = NULL
       return 1

End 

Else
Begin

	set @CompleteFilePath = @ParseFileName

End

return 0
GO
