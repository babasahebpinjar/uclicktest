USE [UC_Facilitate]
GO
/****** Object:  StoredProcedure [dbo].[SP_BSMedConverterAddSequenceToRecord]    Script Date: 5/2/2020 6:47:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_BSMedConverterAddSequenceToRecord]
(
  @FileName varchar(1000),
  @FileNameWithoutPath varchar(1000),
  @ErrorDescription varchar(2000) output,
  @ResultFlag int output
)
As

set @ErrorDescription = NULL
set @ResultFlag = 0

Declare @ScriptAddSequenceToRecords varchar(1000),
        @PerlExecutable varchar(1000),
        @cmd varchar(2000),
		@OutputFileName varchar(1000)

Declare @AccessScopeID int 

Select @AccessScopeID = AccessScopeID
from tb_AccessScope
where AccessScopeName = 'MedConverter'

select @PerlExecutable = ConfigValue
from tb_config
where configname = 'PerlExecutable'
and AccessScopeID = @AccessScopeID

--select @PerlExecutable

select @ScriptAddSequenceToRecords = ConfigValue
from tb_Config
where ConfigName = 'ScriptAddSequenceToRecords'
and AccessScopeID = @AccessScopeID

--select @ScriptAddSequenceToRecords

--------------------------------------------------------
-- Delete in case any old instance of the converted file
-- exists
---------------------------------------------------------

set @OutputFileName = @FileName + '.temp'

Declare @FileExists int = 0

Exec master..xp_fileexist @OutputFileName , @FileExists output 

if ( @FileExists = 1 )
Begin

	set @cmd = 'Del ' + @OutputFileName 
	Exec master..xp_cmdshell @cmd

End

----------------------------------------------------------
-- Call the Perl script to Add SequenceNo to each record
----------------------------------------------------------

if (@PerlExecutable is not NULL)
Begin

			set @cmd = 'ECHO ? && '+'"'+@PerlExecutable+'"' + ' ' + '"' + @ScriptAddSequenceToRecords + '"' + ' ' + '"' +  @FileName + '"'

End

Else
Begin

			set @cmd = 'perl ' + '"' + @ScriptAddSequenceToRecords + '"' + ' ' + '"' +  @FileName + '"' 

End

--print @cmd

Exec master..xp_cmdshell @cmd

------------------------------------------------------------------------
-- Check if the temp file with added sequence numbers is created or not
------------------------------------------------------------------------

set @FileExists = 0

Exec master..xp_fileexist @OutputFileName , @FileExists output 

if ( @FileExists = 1 )
Begin

		---------------------------------------------
		-- Delete the original file from the source
		---------------------------------------------
		set @cmd = 'Del ' + @FileName 
		Exec master..xp_cmdshell @cmd

		----------------------------------------------
		-- Rename the converted file with sequence no 
		-- to the original file
		----------------------------------------------

		set @FileExists = 0

		Exec master..xp_fileexist @FileName , @FileExists output 

		if (@FileExists <> 1)
		Begin

				set @cmd = 'Rename ' + '"' + @OutputFileName + '"' + ' ' + '"' + @FileNameWithoutPath + '"'
				--print @cmd
				Exec master..xp_cmdshell @cmd

		End

		Else 
		Begin

				set @ErrorDescription = 'SP_BSMedConverterAddSequenceToRecord : '+ convert(varchar(30) ,getdate() , 120) +
				' : ' + 'ERROR !!! While renaming the sequence no added file to original file name as original file exists even aftr deletion.'

				set @ResultFlag = 1

				Return

		End

End

Else 
Begin

		set @ErrorDescription = 'SP_BSMedConverterAddSequenceToRecord : '+ convert(varchar(30) ,getdate() , 120) +
		' : ' + 'ERROR !!! Output file with added sequence no not created post running the script.'

		set @ResultFlag = 1

		Return

End










GO
